class_name PluginExtensionDescriptor
extends ValueObject
## Describes one extension exported by a plugin.


#region State

var _extension_id: StringName
var _capability: StringName
var _implementation: Variant
var _metadata: Dictionary[StringName, Variant]

#endregion


#region Construction

## Creates an extension descriptor.
func _init(
	extension_id: StringName,
	capability: StringName,
	implementation: Variant,
	metadata: Dictionary[StringName, Variant] = {}
) -> void:
	assert(
		not extension_id.is_empty(),
		"PluginExtensionDescriptor requires extension_id."
	)
	assert(
		PluginCapability.is_supported(capability),
		"Plugin extension capability is unsupported."
	)
	assert(
		implementation != null,
		"Plugin extension implementation cannot be null."
	)

	_extension_id = extension_id
	_capability = capability
	_implementation = implementation
	_metadata = metadata.duplicate(true)

#endregion


#region Public API

func get_extension_id() -> StringName:
	return _extension_id


func get_capability() -> StringName:
	return _capability


func get_implementation() -> Variant:
	return _implementation


func get_metadata() -> Dictionary[StringName, Variant]:
	return _metadata.duplicate(true)

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_extension_id,
		_capability,
		_implementation,
		_metadata,
	]

#endregion