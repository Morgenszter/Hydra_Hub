class_name EnvironmentReadingTest
extends RefCounted
## Provides EnvironmentReading value-object tests.


#region Tests

static func run() -> void:
	var reading := EnvironmentReading.new(
		EnvironmentMetricType.Value.TEMPERATURE,
		22.5,
		1000,
		&"sensor_01"
	)

	assert(
		reading.get_metric_type()
		== EnvironmentMetricType.Value.TEMPERATURE
	)
	assert(is_equal_approx(reading.get_value(), 22.5))
	assert(reading.get_unit() == "Â°C")
	assert(reading.get_source_id() == &"sensor_01")
	assert(reading.is_available())

#endregion