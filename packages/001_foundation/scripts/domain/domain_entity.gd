@abstract
class_name DomainEntity
extends RefCounted
## Base class for domain objects identified by EntityId.


#region State

var _id: EntityId

#endregion


#region Construction

func _init(id: EntityId) -> void:
	assert(id != null, "DomainEntity requires an EntityId.")
	_id = id

#endregion


#region Public API

func get_id() -> EntityId:
	return _id


func equals(other: DomainEntity) -> bool:
	if other == null:
		return false

	return (
		get_script() == other.get_script()
		and _id.equals(other._id)
	)

#endregion