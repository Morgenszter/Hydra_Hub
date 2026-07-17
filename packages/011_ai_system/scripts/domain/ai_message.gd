class_name AiMessage
extends ValueObject
## Represents one immutable conversational message.


#region State

var _message_id: StringName
var _role: AiMessageRole.Value
var _content: String
var _created_at_unix_ms: int
var _metadata: Dictionary[StringName, Variant]

#endregion


#region Construction

## Creates an immutable conversational message.
func _init(
	role: AiMessageRole.Value,
	content: String,
	metadata: Dictionary[StringName, Variant] = {}
) -> void:
	assert(
		not content.strip_edges().is_empty(),
		"AiMessage requires non-empty content."
	)

	_message_id = StringName(UUID.v4())
	_role = role
	_content = content.strip_edges()
	_created_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)
	_metadata = metadata.duplicate(true)

#endregion


#region Public API

func get_message_id() -> StringName:
	return _message_id


func get_role() -> AiMessageRole.Value:
	return _role


func get_content() -> String:
	return _content


func get_created_at_unix_ms() -> int:
	return _created_at_unix_ms


func get_metadata() -> Dictionary[StringName, Variant]:
	return _metadata.duplicate(true)


func get_metadata_value(
	key: StringName,
	default_value: Variant = null
) -> Variant:
	return _metadata.get(key, default_value)


## Serializes the message to provider-neutral data.
func to_dictionary() -> Dictionary[StringName, Variant]:
	return {
		&"message_id": _message_id,
		&"role": AiMessageRole.to_string_name(_role),
		&"content": _content,
		&"created_at_unix_ms": _created_at_unix_ms,
		&"metadata": _metadata.duplicate(true),
	}

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_message_id,
		_role,
		_content,
		_created_at_unix_ms,
		_metadata,
	]

#endregion