class_name EnvironmentZone
extends AggregateRoot
## Owns the normalized environmental state of one physical zone.


#region Events

const EVENT_UPDATED: StringName = \
	&"hydra.environment.zone.updated"
const EVENT_ALERT_CHANGED: StringName = \
	&"hydra.environment.zone.alert_changed"

#endregion


#region State

var _zone_id: StringName
var _display_name: String
var _readings: Dictionary[int, EnvironmentReading] = {}
var _alert_level: EnvironmentAlertLevel.Value = \
	EnvironmentAlertLevel.Value.UNAVAILABLE
var _updated_at_unix_ms: int = 0

#endregion


#region Construction

func _init(
	id: EntityId,
	zone_id: StringName,
	display_name: String
) -> void:
	super(id)

	assert(not zone_id.is_empty(), "EnvironmentZone requires zone_id.")
	assert(
		not display_name.strip_edges().is_empty(),
		"EnvironmentZone requires display_name."
	)

	_zone_id = zone_id
	_display_name = display_name.strip_edges()

#endregion


#region Public API

func get_zone_id() -> StringName:
	return _zone_id


func get_display_name() -> String:
	return _display_name


func get_alert_level() -> EnvironmentAlertLevel.Value:
	return _alert_level


func get_updated_at_unix_ms() -> int:
	return _updated_at_unix_ms


func get_reading(
	metric_type: EnvironmentMetricType.Value
) -> EnvironmentReading:
	return _readings.get(metric_type)


func get_readings() -> Array[EnvironmentReading]:
	var result: Array[EnvironmentReading] = []

	for reading: EnvironmentReading in _readings.values():
		result.append(reading)

	return result


## Replaces current readings and evaluates alert severity.
func update_readings(
	readings: Array[EnvironmentReading],
	thresholds: EnvironmentThresholds
) -> Result:
	if thresholds == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Environment thresholds cannot be null."
			)
		)

	var previous_alert_level := _alert_level
	_readings.clear()

	for reading in readings:
		if reading == null:
			continue

		_readings[reading.get_metric_type()] = reading

	_alert_level = _evaluate_alert_level(thresholds)
	_updated_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_UPDATED,
			{
				&"zone_id": _zone_id,
				&"reading_count": _readings.size(),
				&"alert_level":
					EnvironmentAlertLevel.to_label(
						_alert_level
					),
			}
		)
	)

	if previous_alert_level != _alert_level:
		_record_domain_event(
			DomainEvent.new(
				EVENT_ALERT_CHANGED,
				{
					&"zone_id": _zone_id,
					&"previous_level":
						EnvironmentAlertLevel.to_label(
							previous_alert_level
						),
					&"current_level":
						EnvironmentAlertLevel.to_label(
							_alert_level
						),
				}
			)
		)

	return Result.success()

#endregion


#region Private methods

func _evaluate_alert_level(
	thresholds: EnvironmentThresholds
) -> EnvironmentAlertLevel.Value:
	if _readings.is_empty():
		return EnvironmentAlertLevel.Value.UNAVAILABLE

	var highest_level := EnvironmentAlertLevel.Value.NORMAL

	for reading: EnvironmentReading in _readings.values():
		var level := _evaluate_reading(reading, thresholds)

		if level == EnvironmentAlertLevel.Value.CRITICAL:
			return level

		if level == EnvironmentAlertLevel.Value.WARNING:
			highest_level = level

	return highest_level


func _evaluate_reading(
	reading: EnvironmentReading,
	thresholds: EnvironmentThresholds
) -> EnvironmentAlertLevel.Value:
	if not reading.is_available():
		return EnvironmentAlertLevel.Value.UNAVAILABLE

	var value := reading.get_value()

	match reading.get_metric_type():
		EnvironmentMetricType.Value.TEMPERATURE:
			if (
				value <= thresholds.minimum_temperature_critical_celsius
				or value >= thresholds.maximum_temperature_critical_celsius
			):
				return EnvironmentAlertLevel.Value.CRITICAL

			if (
				value <= thresholds.minimum_temperature_warning_celsius
				or value >= thresholds.maximum_temperature_warning_celsius
			):
				return EnvironmentAlertLevel.Value.WARNING

		EnvironmentMetricType.Value.HUMIDITY:
			if value >= thresholds.maximum_humidity_critical_percent:
				return EnvironmentAlertLevel.Value.CRITICAL

			if (
				value <= thresholds.minimum_humidity_warning_percent
				or value >= thresholds.maximum_humidity_warning_percent
			):
				return EnvironmentAlertLevel.Value.WARNING

		EnvironmentMetricType.Value.CO2:
			if value >= thresholds.co2_critical_ppm:
				return EnvironmentAlertLevel.Value.CRITICAL

			if value >= thresholds.co2_warning_ppm:
				return EnvironmentAlertLevel.Value.WARNING

		EnvironmentMetricType.Value.PM25:
			if value >= thresholds.pm25_critical_ug_m3:
				return EnvironmentAlertLevel.Value.CRITICAL

			if value >= thresholds.pm25_warning_ug_m3:
				return EnvironmentAlertLevel.Value.WARNING

		EnvironmentMetricType.Value.VOC_INDEX:
			if value >= thresholds.voc_critical_index:
				return EnvironmentAlertLevel.Value.CRITICAL

			if value >= thresholds.voc_warning_index:
				return EnvironmentAlertLevel.Value.WARNING

	return EnvironmentAlertLevel.Value.NORMAL

#endregion