class_name InputNaturalness

const MIN_SAMPLES := 24
const FULL_CONFIDENCE_SAMPLES := 120

const TARGET_BIN_WIDTH_MS := 4.0

const PERFECT_SIGMA_START := 0.8
const PERFECT_SIGMA_END := 3.0


static func calculate(
	errors_ms: Array[float],
	max_abs_ms: float
) -> float:
	return analyze(errors_ms, max_abs_ms).score


static func analyze(
	errors_ms: Array[float],
	max_abs_ms: float
) -> Dictionary:
	if errors_ms.size() < MIN_SAMPLES or max_abs_ms <= 0.0:
		return {
			"score": 50.0,
			"confidence": 0.0,
			"sigma": 0.0,
			"mean": 0.0,
			"uniform_rejection": 0.0,
			"gaussian_similarity": 0.0,
			"flatness_score": 0.0,
			"temporal_score": 0.0,
		}

	var values: Array[float] = []
	values.resize(errors_ms.size())

	for i in range(errors_ms.size()):
		values[i] = clampf(
			errors_ms[i],
			-max_abs_ms,
			max_abs_ms
		)

	var mean := _mean(values)
	var sigma := _standard_deviation(values, mean)

	var bin_count := clampi(
		int(round((max_abs_ms * 2.0) / TARGET_BIN_WIDTH_MS)),
		17,
		101
	)

	if bin_count % 2 == 0:
		bin_count += 1

	var histogram := _make_histogram(
		values,
		max_abs_ms,
		bin_count
	)

	var uniform := _make_uniform_distribution(bin_count)

	var gaussian := _make_gaussian_distribution(
		mean,
		sigma,
		max_abs_ms,
		bin_count
	)

	# 0 = uniform과 동일
	# 1 = uniform과 매우 다름
	var uniform_js := _js_divergence(histogram, uniform)

	# 0 = Gaussian과 동일
	# 1 = Gaussian과 매우 다름
	var gaussian_js := _js_divergence(histogram, gaussian)

	# 랜덤 uniform bot 제거.
	var uniform_rejection := _smoothstep(
		0.03,
		0.22,
		uniform_js
	)

	# 인간 판정은 대체로 중앙 근처 봉우리 형태.
	var gaussian_similarity := 1.0 - _smoothstep(
		0.12,
		0.40,
		gaussian_js
	)

	# Uniform distribution은 excess kurtosis가 약 -1.2.
	# Gaussian은 0.
	var kurtosis := _excess_kurtosis(values, mean, sigma)

	var flatness_score := _smoothstep(
		-1.05,
		-0.25,
		kurtosis
	)

	# 0~1ms 수준으로 지나치게 몰려있는 완벽 입력 방지.
	var spread_score := _smoothstep(
		PERFECT_SIGMA_START,
		PERFECT_SIGMA_END,
		sigma
	)

	# 인간은 순간적으로 early/late 방향으로 drift하는 경향이 있으므로
	# 연속 판정의 상관관계를 약하게 참고함.
	var lag_correlation := _lag1_correlation(values, mean, sigma)

	var temporal_evidence := _smoothstep(
		0.04,
		0.25,
		lag_correlation
	)

	# temporal correlation이 없어도 바로 bot으로 취급하진 않음.
	var temporal_score := lerpf(
		0.5,
		1.0,
		temporal_evidence
	)

	# flatness는 완전 hard gate로 쓰면 실제 사람의 이상한 분포에도
	# 지나치게 민감하므로 25%까지는 남겨둠.
	var flatness_gate := lerpf(
		0.25,
		1.0,
		flatness_score
	)

	var shape_quality := (
		gaussian_similarity * 0.70
		+ temporal_score * 0.30
	)

	var raw_score := (
		100.0
		* uniform_rejection
		* flatness_gate
		* spread_score
		* shape_quality
	)

	raw_score = clampf(raw_score, 0.0, 100.0)

	# 표본이 24~120개 정도밖에 없으면 50점 쪽으로 수축.
	# 데이터 몇 개만 보고 bot 판정을 내리는 것을 방지.
	var confidence := _smoothstep(
		float(MIN_SAMPLES),
		float(FULL_CONFIDENCE_SAMPLES),
		float(values.size())
	)

	var score := lerpf(
		50.0,
		raw_score,
		confidence
	)

	return {
		"score": score,
		"raw_score": raw_score,
		"confidence": confidence,

		"mean": mean,
		"sigma": sigma,
		"kurtosis": kurtosis,
		"lag_correlation": lag_correlation,

		"uniform_js": uniform_js,
		"gaussian_js": gaussian_js,

		"uniform_rejection": uniform_rejection,
		"gaussian_similarity": gaussian_similarity,
		"flatness_score": flatness_score,
		"spread_score": spread_score,
		"temporal_score": temporal_score,

		"sample_count": values.size(),
		"bin_count": bin_count,
	}


static func _mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0

	var total := 0.0

	for value in values:
		total += value

	return total / values.size()


static func _standard_deviation(
	values: Array[float],
	mean: float
) -> float:
	if values.size() < 2:
		return 0.0

	var total := 0.0

	for value in values:
		var delta := value - mean
		total += delta * delta

	return sqrt(total / values.size())


static func _make_histogram(
	values: Array[float],
	max_abs_ms: float,
	bin_count: int
) -> Array[float]:
	var histogram: Array[float] = []
	histogram.resize(bin_count)
	histogram.fill(0.0)

	var width := (max_abs_ms * 2.0) / bin_count

	for value in values:
		var index := int(floor(
			(value + max_abs_ms) / width
		))

		index = clampi(
			index,
			0,
			bin_count - 1
		)

		histogram[index] += 1.0

	# 아주 작은 Laplace smoothing.
	# 빈 bin 때문에 divergence가 과하게 튀는 것을 방지.
	const SMOOTHING := 0.15

	var total := (
		float(values.size())
		+ SMOOTHING * bin_count
	)

	for i in range(bin_count):
		histogram[i] = (
			histogram[i] + SMOOTHING
		) / total

	return histogram


static func _make_uniform_distribution(
	bin_count: int
) -> Array[float]:
	var result: Array[float] = []
	result.resize(bin_count)

	var probability := 1.0 / bin_count

	for i in range(bin_count):
		result[i] = probability

	return result


static func _make_gaussian_distribution(
	mean: float,
	sigma: float,
	max_abs_ms: float,
	bin_count: int
) -> Array[float]:
	var result: Array[float] = []
	result.resize(bin_count)

	var width := (max_abs_ms * 2.0) / bin_count

	# sigma=0에서 계산 터지는 것 방지.
	var safe_sigma := maxf(
		sigma,
		width * 0.5
	)

	var total := 0.0

	for i in range(bin_count):
		var center := (
			-max_abs_ms
			+ (float(i) + 0.5) * width
		)

		var z := (center - mean) / safe_sigma

		var probability := exp(
			-0.5 * z * z
		)

		result[i] = probability
		total += probability

	if total > 0.0:
		for i in range(bin_count):
			result[i] /= total

	return result


static func _js_divergence(
	p: Array[float],
	q: Array[float]
) -> float:
	var result := 0.0

	for i in range(p.size()):
		var pv := p[i]
		var qv := q[i]
		var m := (pv + qv) * 0.5

		if pv > 0.0:
			result += (
				0.5
				* pv
				* log(pv / m)
			)

		if qv > 0.0:
			result += (
				0.5
				* qv
				* log(qv / m)
			)

	# JS divergence 최대값 ln(2)를 나눠서 0~1로 정규화.
	return result / log(2.0)


static func _excess_kurtosis(
	values: Array[float],
	mean: float,
	sigma: float
) -> float:
	if sigma < 0.000001:
		return -3.0

	var fourth_moment := 0.0

	for value in values:
		var delta := value - mean
		fourth_moment += (
			delta * delta * delta * delta
		)

	fourth_moment /= values.size()

	return (
		fourth_moment
		/ pow(sigma, 4.0)
		- 3.0
	)


static func _lag1_correlation(
	values: Array[float],
	mean: float,
	sigma: float
) -> float:
	if values.size() < 3 or sigma < 0.000001:
		return 0.0

	var covariance := 0.0

	for i in range(values.size() - 1):
		covariance += (
			(values[i] - mean)
			* (values[i + 1] - mean)
		)

	covariance /= values.size() - 1

	return clampf(
		covariance / (sigma * sigma),
		-1.0,
		1.0
	)


static func _smoothstep(
	from: float,
	to: float,
	value: float
) -> float:
	if is_equal_approx(from, to):
		return float(value >= to)

	var t := clampf(
		(value - from) / (to - from),
		0.0,
		1.0
	)

	return t * t * (3.0 - 2.0 * t)
