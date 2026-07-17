class_name NotificationRequest
extends ValueObject
## Represents an immutable notification submission request.


#region State

var _source_id: StringName
var _category: StringName
var _title: String
var _message: String
var _priority: NotificationPriority.Value
var _duration_seconds: float
var _metadata: Dictionary[StringName, Variant]

#endregion


#region Construction

## Creates an immutable notification request.
func _init(
	source_id: StringName,
	category: StringName,
	title: String,
	message: String,
	priority: NotificationPriority.Value,
	duration_seconds: float,
	metadata: Dictionary[StringName, Variant] = {}
) -> void:
	assert(
		not source_id.is_empty(),
		"NotificationRequest requires source_id."
	)
	assert(
		not category.is_empty(),
		"NotificationRequest requires category."
	)
	assert(
		not title.strip_edges().is_empty(),
		"NotificationRequest requires title."
	)
	assert(
		duration_seconds >= 0.0,
		"Notification duration cannot be negative."
	)

	_source_id = source_id
	_category = category
	_title = title.strip_edges()
	_message = message.strip_edges()
	_priority = priority
	_duration_seconds = duration_seconds
	_metadata = metadata.duplicate(true)

#endregion


#region Public API

func get_source_id() -> StringName:
	return _source_id


func get_category() -> StringName:
	return _category


func get_title() -> String:
	return _title


func get_message() -> String:
	return _message


func get_priority() -> NotificationPriority.Value:
	return _priority


func get_duration_seconds() -> float:
	return _duration_seconds


func get_metadata() -> Dictionary[StringName, Variant]:
	return _metadata.duplicate(true)

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_source_id,
		_category,
		_title,
		_message,
		_priority,
		_duration_seconds,
		_metadata,
	]

#endregion