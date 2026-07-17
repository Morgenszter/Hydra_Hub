class_name DeviceCommand
extends RefCounted
## Represents an immutable command addressed to one normalized device.


#region State

var _command_id: StringName
var _device_id: StringName
var _command_name: StringName
var _arguments: Dictionary[StringName, Variant]
var _created_at_unix_ms: int
var _correlation_id: StringName

#endregion


#region Construction

## Creates a device command.
func _init(
	device_id: StringName,
	command_name: StringName,
	arguments: Dictionary[StringName, Variant] = {},
	correlation_id: StringName = &""
) -> void:
	assert(
		not device_id.is_empty(),
		"DeviceCommand requires device_id."
	)
	assert(
		not command_name.is_empty(),
		"DeviceCommand requires command_name."
	)

	_command_id = StringName(UUID.v4())
	_device_id = device_id
	_command_name = command_name
	_arguments = arguments.duplicate(true)
	_created_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)
	_correlation_id = correlation_id

	if _correlation_id.is_empty():
		_correlation_id = _command_id

#endregion


#region Public API

func get_command_id() -> StringName:
	return _command_id


func get_device_id() -> StringName:
	return _device_id


func get_command_name() -> StringName:
	return _command_name


func get_arguments() -> Dictionary[StringName, Variant]:
	return _arguments.duplicate(true)


func get_argument(
	argument_name: StringName,
	default_value: Variant = null
) -> Variant:
	return _arguments.get(argument_name, default_value)


func get_created_at_unix_ms() -> int:
	return _created_at_unix_ms


func get_correlation_id() -> StringName:
	return _correlation_id

#endregion