class_name EnvironmentReading
extends ValueObject
## Represents one immutable normalized environmental reading.


#region State

var _metric_type: EnvironmentMetricType.Value
var _value: float
var _unit: String
var _measured_at_unix_ms: int
var _source_id: StringName
var _available: bool

#endregion


#region Construction

## Creates a normalized environmental reading.
func _init(
	metric_type: EnvironmentMetricType.Value,
	value: float,
	measured_at_unix_ms: int,
	source_id: StringName,
	available: bool = true
) -> void:
	assert(
		measured_at_unix_ms >= 0,
		"EnvironmentReading timestamp cannot be negative."
	)
	assert(
		not source_id.is_empty(),
		"EnvironmentReading requires source_id."
	)

	_metric_type = metric_type
	_value = value
	_unit = EnvironmentMetricType.get_unit(metric_type)
	_measured_at_unix_ms = measured_at_unix_ms
	_source_id = source_id
	_available = available

#endregion


#region Public API

func get_metric_type() -> EnvironmentMetricType.Value:
	return _metric_type


func get_value() -> float:
	return _value


func get_unit() -> String:
	return _unit


func get_measured_at_unix_ms() -> int:
	return _measured_at_unix_ms


func get_source_id() -> StringName:
	return _source_id


func is_available() -> bool:
	return _available

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_metric_type,
		_value,
		_unit,
		_measured_at_unix_ms,
		_source_id,
		_available,
	]

#endregion