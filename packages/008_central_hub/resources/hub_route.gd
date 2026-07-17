class_name HubRoute
extends Resource
## Defines one navigable Central Hub destination.


#region Identity

@export_group("Identity")
@export var route_id: StringName = &""
@export var package_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

#endregion


#region Presentation

@export_group("Presentation")
@export var scene_path: String = ""
@export var icon_path: String = ""
@export var sort_order: int = 0
@export var accent_color: Color = Color("#32d8ff")

#endregion


#region Access

@export_group("Access")
@export var enabled: bool = true
@export var visible: bool = true

#endregion


#region Validation

## Returns a structured validation result.
func validate() -> Result:
	if route_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Hub route requires route_id."
			)
		)

	if package_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Hub route requires package_id.",
				{&"route_id": route_id}
			)
		)

	if display_name.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Hub route requires display_name.",
				{&"route_id": route_id}
			)
		)

	if scene_path.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Hub route requires scene_path.",
				{&"route_id": route_id}
			)
		)

	return Result.success()

#endregion