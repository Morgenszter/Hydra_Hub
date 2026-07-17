class_name AndroidPlatformInfo
extends ValueObject
## Represents immutable Android platform information.


#region State

var _is_android: bool
var _operating_system_name: String
var _model_name: String
var _sdk_version: int
var _capabilities: Dictionary[StringName, bool]

#endregion


#region Construction

## Creates normalized platform information.
func _init(
	is_android: bool,
	operating_system_name: String,
	model_name: String,
	sdk_version: int,
	capabilities: Dictionary[StringName, bool]
) -> void:
	assert(
		sdk_version >= 0,
		"Android SDK version cannot be negative."
	)

	_is_android = is_android
	_operating_system_name = operating_system_name.strip_edges()
	_model_name = model_name.strip_edges()
	_sdk_version = sdk_version
	_capabilities = capabilities.duplicate(true)

#endregion


#region Public API

func is_android() -> bool:
	return _is_android


func get_operating_system_name() -> String:
	return _operating_system_name


func get_model_name() -> String:
	return _model_name


func get_sdk_version() -> int:
	return _sdk_version


func has_capability(
	capability: StringName
) -> bool:
	return _capabilities.get(capability, false)


func get_capabilities() -> Dictionary[StringName, bool]:
	return _capabilities.duplicate(true)

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_is_android,
		_operating_system_name,
		_model_name,
		_sdk_version,
		_capabilities,
	]

#endregion