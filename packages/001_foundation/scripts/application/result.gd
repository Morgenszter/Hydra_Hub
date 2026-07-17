class_name Result
extends RefCounted
## Represents a successful or failed application operation.


#region State

var _successful: bool
var _value: Variant
var _error: DomainError

#endregion


#region Construction

func _init(
	successful: bool,
	value: Variant = null,
	error: DomainError = null
) -> void:
	_successful = successful
	_value = value
	_error = error


static func success(value: Variant = null) -> Result:
	return Result.new(true, value)


static func failure(error: DomainError) -> Result:
	assert(error != null, "Result.failure() requires DomainError.")
	return Result.new(false, null, error)

#endregion


#region Public API

func is_success() -> bool:
	return _successful


func is_failure() -> bool:
	return not _successful


func get_value() -> Variant:
	assert(_successful, "Failed Result has no value.")
	return _value


func get_error() -> DomainError:
	assert(not _successful, "Successful Result has no error.")
	return _error

#endregion