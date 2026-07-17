class_name DomainError
extends RefCounted
## Represents a structured domain or application failure.


#region State

var _code: StringName
var _message: String
var _details: Dictionary[StringName, Variant]

#endregion


#region Construction

func _init(
	code: StringName,
	message: String,
	details: Dictionary[StringName, Variant] = {}
) -> void:
	assert(not code.is_empty(), "DomainError code cannot be empty.")
	assert(not message.is_empty(), "DomainError message cannot be empty.")

	_code = code
	_message = message
	_details = details.duplicate(true)

#endregion


#region Public API

func get_code() -> StringName:
	return _code


func get_message() -> String:
	return _message


func get_details() -> Dictionary[StringName, Variant]:
	return _details.duplicate(true)


func to_dictionary() -> Dictionary[StringName, Variant]:
	return {
		&"code": _code,
		&"message": _message,
		&"details": _details.duplicate(true),
	}

#endregion