class_name EnvironmentZoneTest
extends RefCounted
## Provides EnvironmentZone alert-evaluation tests.


#region Tests

static func run() -> void:
	var zone := EnvironmentZone.new(
		EntityId.generate(),
		&"office",
		"OFFICE"
	)
	var thresholds := EnvironmentThresholds.new()
	var timestamp := 1000

	var normal_readings: Array[EnvironmentReading] = [
		EnvironmentReading.new(
			EnvironmentMetricType.Value.TEMPERATURE,
			22.0,
			timestamp,
			&"temperature"
		),
		EnvironmentReading.new(
			EnvironmentMetricType.Value.CO2,
			700.0,
			timestamp,
			&"co2"
		),
	]

	assert(
		zone.update_readings(
			normal_readings,
			thresholds
		).is_success()
	)
	assert(
		zone.get_alert_level()
		== EnvironmentAlertLevel.Value.NORMAL
	)

	var warning_readings: Array[EnvironmentReading] = [
		EnvironmentReading.new(
			EnvironmentMetricType.Value.CO2,
			1200.0,
			timestamp,
			&"co2"
		),
	]

	assert(
		zone.update_readings(
			warning_readings,
			thresholds
		).is_success()
	)
	assert(
		zone.get_alert_level()
		== EnvironmentAlertLevel.Value.WARNING
	)

#endregion