class_name DeviceStateSnapshot
extends ValueObject
## Represents an immutable normalized device-state snapshot.


#region State

var _device_id: StringName
var _connection_state: DeviceConnectionState.Value
var _properties: Dictionary[StringName, Variant]
var _updated_at_unix_ms: int
var _battery_percent: float
var _signal_strength_percent: float

#endregion


#region Construction

## Creates a normalized device-state snapshot.
func _init(
	device_id: StringName,
	connection_state: DeviceConnectionState.Value,
	properties: Dictionary[StringName, Variant],
	updated_at_unix_ms: int,
	battery_percent: float = -1.0,
	signal_strength_percent: float = -1.0
) -> void:
	assert(
		not device_id.is_empty(),
		"DeviceStateSnapshot requires device_id."
	)
	assert(
		updated_at_unix_ms >= 0,
		"DeviceStateSnapshot timestamp cannot be negative."
	)

	_device_id = device_id
	_connection_state = connection_state
	_properties = properties.duplicate(true)
	_updated_at_unix_ms = updated_at_unix_ms
	_battery_percent = battery_percent
	_signal_strength_percent = signal_strength_percent

#endregion


#region Public API

func get_device_id() -> StringName:
	return _device_id


func get_connection_state() -> DeviceConnectionState.Value:
	return _connection_state


func get_properties() -> Dictionary[StringName, Variant]:
	return _properties.duplicate(true)


func get_property(
	property_id: StringName,
	default_value: Variant = null
) -> Variant:
	return _properties.get(property_id, default_value)


func get_updated_at_unix_ms() -> int:
	return _updated_at_unix_ms


func get_battery_percent() -> float:
	return _battery_percent


func get_signal_strength_percent() -> float:
	return _signal_strength_percent

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_device_id,
		_connection_state,
		_properties,
		_updated_at_unix_ms,
		_battery_percent,
		_signal_strength_percent,
	]

#endregion