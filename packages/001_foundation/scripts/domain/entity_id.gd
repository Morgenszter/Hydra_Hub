class_name EntityId
extends RefCounted
## Represents an immutable domain entity identifier.


#region State

var _value: StringName

#endregion


#region Construction

func _init(value: StringName) -> void:
	assert(not value.is_empty(), "EntityId cannot be empty.")
	_value = value


static func generate() -> EntityId:
	return EntityId.new(StringName(UUID.v4()))


static func from_string(value: String) -> EntityId:
	var normalized := value.strip_edges()
	assert(not normalized.is_empty(), "EntityId cannot be empty.")

	return EntityId.new(StringName(normalized))

#endregion


#region Public API

func get_value() -> StringName:
	return _value


func as_string() -> String:
	return String(_value)


func equals(other: EntityId) -> bool:
	return other != null and _value == other._value


func get_hash() -> int:
	return hash(_value)

#endregion


#region Object

func _to_string() -> String:
	return as_string()

#endregion