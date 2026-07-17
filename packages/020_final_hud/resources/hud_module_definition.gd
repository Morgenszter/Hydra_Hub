class_name HudModuleDefinition
extends Resource
## Defines one module available in the Final HUD shell.


#region Identity

@export_group("Identity")
@export var route_id: StringName = &""
@export var display_name: String = ""
@export var short_label: String = ""
@export var package_id: StringName = &""

#endregion


#region Scene

@export_group("Scene")
@export_file("*.tscn") var scene_path: String = ""
@export var sort_order: int = 0
@export var enabled: bool = true

#endregion


#region Presentation

@export_group("Presentation")
@export var accent_color: Color = Color("#32d8ff")
@export_multiline var description: String = ""

#endregion


#region Validation

## Validates the HUD module definition.
func validate() -> Result:
	if route_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"HUD module requires route_id."
			)
		)

	if display_name.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"HUD module requires display_name."
			)
		)

	if scene_path.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"HUD module requires scene_path."
			)
		)

	if not scene_path.begins_with("res://"):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"HUD module scene path must use res://."
			)
		)

	return Result.success()

#endregion