class_name InstallationOperation
extends ValueObject
## Represents one immutable installation file operation.


#region Operation types

enum Type {
	CREATE_DIRECTORY,
	WRITE_TEXT_FILE,
	REMOVE_FILE,
}

#endregion


#region State

var _operation_id: StringName
var _type: Type
var _relative_path: String
var _content: String
var _replace_existing: bool

#endregion


#region Construction

## Creates an installation operation.
func _init(
	type: Type,
	relative_path: String,
	content: String = "",
	replace_existing: bool = false
) -> void:
	assert(
		not relative_path.strip_edges().is_empty(),
		"InstallationOperation requires relative_path."
	)

	_operation_id = StringName(
		"install-%s-%s"
		% [
			Time.get_ticks_usec(),
			randi(),
		]
	)
	_type = type
	_relative_path = relative_path.strip_edges()
	_content = content
	_replace_existing = replace_existing

#endregion


#region Public API

func get_operation_id() -> StringName:
	return _operation_id


func get_type() -> Type:
	return _type


func get_relative_path() -> String:
	return _relative_path


func get_content() -> String:
	return _content


func can_replace_existing() -> bool:
	return _replace_existing


func validate() -> Result:
	if _relative_path.is_absolute_path():
		return _invalid_path()

	if _relative_path.contains(".."):
		return _invalid_path()

	if _relative_path.begins_with("/"):
		return _invalid_path()

	return Result.success()

#endregion


#region Private methods

func _invalid_path() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_ARGUMENT,
			"Installation operation contains an unsafe path.",
			{
				&"relative_path": _relative_path,
			}
		)
	)

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_operation_id,
		_type,
		_relative_path,
		_content,
		_replace_existing,
	]

#endregion