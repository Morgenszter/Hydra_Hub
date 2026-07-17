class_name RoomSummary
extends ValueObject
## Represents an immutable room overview snapshot.


#region State

var _room_id: StringName
var _display_name: String
var _occupied: bool
var _temperature_celsius: float
var _active_device_count: int
var _alert_count: int

#endregion


#region Construction

## Creates a room summary snapshot.
func _init(
	room_id: StringName,
	display_name: String,
	occupied: bool,
	temperature_celsius: float,
	active_device_count: int,
	alert_count: int
) -> void:
	assert(not room_id.is_empty(), "RoomSummary requires room_id.")
	assert(
		not display_name.strip_edges().is_empty(),
		"RoomSummary requires display_name."
	)
	assert(
		active_device_count >= 0,
		"RoomSummary active_device_count cannot be negative."
	)
	assert(
		alert_count >= 0,
		"RoomSummary alert_count cannot be negative."
	)

	_room_id = room_id
	_display_name = display_name.strip_edges()
	_occupied = occupied
	_temperature_celsius = temperature_celsius
	_active_device_count = active_device_count
	_alert_count = alert_count

#endregion


#region Public API

func get_room_id() -> StringName:
	return _room_id


func get_display_name() -> String:
	return _display_name


func is_occupied() -> bool:
	return _occupied


func get_temperature_celsius() -> float:
	return _temperature_celsius


func get_active_device_count() -> int:
	return _active_device_count


func get_alert_count() -> int:
	return _alert_count

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_room_id,
		_display_name,
		_occupied,
		_temperature_celsius,
		_active_device_count,
		_alert_count,
	]

#endregion