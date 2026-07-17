class_name DeviceDescriptor
extends ValueObject
## Represents immutable device identity and capability metadata.


#region State

var _device_id: StringName
var _provider_id: StringName
var _display_name: String
var _manufacturer: String
var _model: String
var _zone_id: StringName
var _capabilities: Array[DeviceCapability.Value]
var _enabled: bool

#endregion


#region Construction

## Creates normalized device metadata.
func _init(
	device_id: StringName,
	provider_id: StringName,
	display_name: String,
	manufacturer: String,
	model: String,
	zone_id: StringName,
	capabilities: Array[DeviceCapability.Value],
	enabled: bool = true
) -> void:
	assert(
		not device_id.is_empty(),
		"DeviceDescriptor requires device_id."
	)
	assert(
		not provider_id.is_empty(),
		"DeviceDescriptor requires provider_id."
	)
	assert(
		not display_name.strip_edges().is_empty(),
		"DeviceDescriptor requires display_name."
	)

	_device_id = device_id
	_provider_id = provider_id
	_display_name = display_name.strip_edges()
	_manufacturer = manufacturer.strip_edges()
	_model = model.strip_edges()
	_zone_id = zone_id
	_capabilities = capabilities.duplicate()
	_enabled = enabled

#endregion


#region Public API

func get_device_id() -> StringName:
	return _device_id


func get_provider_id() -> StringName:
	return _provider_id


func get_display_name() -> String:
	return _display_name


func get_manufacturer() -> String:
	return _manufacturer


func get_model() -> String:
	return _model


func get_zone_id() -> StringName:
	return _zone_id


func get_capabilities() -> Array[DeviceCapability.Value]:
	return _capabilities.duplicate()


func is_enabled() -> bool:
	return _enabled


func has_capability(
	capability: DeviceCapability.Value
) -> bool:
	return capability in _capabilities

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_device_id,
		_provider_id,
		_display_name,
		_manufacturer,
		_model,
		_zone_id,
		_capabilities,
		_enabled,
	]

#endregion