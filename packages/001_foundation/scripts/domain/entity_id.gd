class_name EntityId
extends ValueObject
## Represents an immutable entity identifier.


#region State

var _value: StringName

#endregion


#region Construction

func _init(value: StringName) -> void:
	assert(not value.is_empty(), "EntityId cannot be empty.")

	_value = value


## Generates a unique runtime entity identifier.
static func generate() -> EntityId:
	var generated_value := StringName(
		"%s-%s-%s"
		% [
			Time.get_unix_time_from_system(),
			Time.get_ticks_usec(),
			randi(),
		]
	)

	return EntityId.new(generated_value)


## Creates an entity identifier from text.
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

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [_value]

#endregion
