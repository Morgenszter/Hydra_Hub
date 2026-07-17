@abstract
class_name ValueObject
extends RefCounted
## Base class for immutable value objects.


#region Public API

func equals(other: ValueObject) -> bool:
	if other == null:
		return false

	if get_script() != other.get_script():
		return false

	return _get_atomic_values() == other._get_atomic_values()


func get_hash() -> int:
	return hash(_get_atomic_values())

#endregion


#region Extension points

@abstract
func _get_atomic_values() -> Array[Variant]

#endregion