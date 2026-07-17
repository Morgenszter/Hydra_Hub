class_name PluginManifest
extends Resource
## Declares plugin identity, compatibility and requested capabilities.


#region Identity

@export_group("Identity")
@export var plugin_id: StringName = &""
@export var display_name: String = ""
@export var version: String = "0.1.0"
@export var author: String = ""
@export_multiline var description: String = ""

#endregion


#region Compatibility

@export_group("Compatibility")
@export var minimum_hydra_version: String = "0.1.0"
@export var minimum_godot_version: String = "4.7"
@export var entry_script_path: String = ""

#endregion


#region Dependencies

@export_group("Dependencies")
@export var required_plugins: PackedStringArray = PackedStringArray()
@export var requested_capabilities: PackedStringArray = PackedStringArray()

#endregion


#region Validation

## Validates required manifest fields.
func validate() -> Result:
	if plugin_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin manifest requires plugin_id."
			)
		)

	if display_name.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin manifest requires display_name.",
				{&"plugin_id": plugin_id}
			)
		)

	if version.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin manifest requires version.",
				{&"plugin_id": plugin_id}
			)
		)

	if entry_script_path.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin manifest requires entry_script_path.",
				{&"plugin_id": plugin_id}
			)
		)

	if not entry_script_path.begins_with("res://"):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin entry script must use a res:// path.",
				{&"plugin_id": plugin_id}
			)
		)

	return Result.success()

#endregion