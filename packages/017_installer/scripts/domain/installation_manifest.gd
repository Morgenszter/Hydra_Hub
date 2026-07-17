class_name InstallationManifest
extends Resource
## Describes one installable HYDRA package.


#region Identity

@export_group("Identity")
@export var package_id: StringName = &""
@export var display_name: String = ""
@export var version: String = "0.1.0"

#endregion


#region Compatibility

@export_group("Compatibility")
@export var minimum_hydra_version: String = "0.1.0"
@export var required_packages: PackedStringArray = PackedStringArray()

#endregion


#region Metadata

@export_group("Metadata")
@export_multiline var description: String = ""
@export var checksum: String = ""

#endregion


#region Validation

## Validates required manifest fields.
func validate() -> Result:
	if package_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Installation manifest requires package_id."
			)
		)

	if display_name.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Installation manifest requires display_name."
			)
		)

	if version.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Installation manifest requires version."
			)
		)

	return Result.success()

#endregion