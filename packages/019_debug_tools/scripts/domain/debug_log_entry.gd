class_name DebugLogEntry
extends ValueObject
## Represents one immutable runtime debug log entry.


#region State

var _entry_id: StringName
var _level: DebugLogLevel.Value
var _source: StringName
var _message: String
var _metadata: Dictionary[StringName, Variant]
var _recorded_at_unix_ms: int

#endregion


#region Construction

## Creates an immutable debug log entry.
func _init(
	level: DebugLogLevel.Value,
	source: StringName,
	message: String,
	metadata: Dictionary[StringName, Variant] = {}
) -> void:
	assert(
		not source.is_empty(),
		"DebugLogEntry requires source."
	)
	assert(
		not message.strip_edges().is_empty(),
		"DebugLogEntry requires message."
	)

	_entry_id = StringName(
		"debug-%s-%s"
		% [
			Time.get_ticks_usec(),
			randi(),
		]
	)
	_level = level
	_source = source
	_message = message.strip_edges()
	_metadata = metadata.duplicate(true)
	_recorded_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)

#endregion


#region Public API

func get_entry_id() -> StringName:
	return _entry_id


func get_level() -> DebugLogLevel.Value:
	return _level


func get_source() -> StringName:
	return _source


func get_message() -> String:
	return _message


func get_metadata() -> Dictionary[StringName, Variant]:
	return _metadata.duplicate(true)


func get_recorded_at_unix_ms() -> int:
	return _recorded_at_unix_ms

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_entry_id,
		_level,
		_source,
		_message,
		_metadata,
		_recorded_at_unix_ms,
	]

#endregion