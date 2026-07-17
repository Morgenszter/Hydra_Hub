class_name HomeOverview
extends AggregateRoot
## Represents the aggregated operational state of a managed home.


#region Events

const EVENT_UPDATED: StringName = &"hydra.home.overview.updated"
const EVENT_STATE_CHANGED: StringName = &"hydra.home.state.changed"
const EVENT_SECURITY_CHANGED: StringName = &"hydra.home.security.changed"

#endregion


#region State

var _display_name: String
var _operational_state: HomeOperationalState.Value = \
	HomeOperationalState.Value.UNKNOWN
var _security_state: SecurityState.Value = SecurityState.Value.UNKNOWN
var _occupant_count: int = 0
var _current_power_watts: float = 0.0
var _room_summaries: Array[RoomSummary] = []
var _updated_at_unix_ms: int = 0

#endregion


#region Construction

## Creates a home overview aggregate.
func _init(
	id: EntityId,
	display_name: String
) -> void:
	super(id)

	assert(
		not display_name.strip_edges().is_empty(),
		"HomeOverview requires display_name."
	)

	_display_name = display_name.strip_edges()

#endregion


#region Public API

func get_display_name() -> String:
	return _display_name


func get_operational_state() -> HomeOperationalState.Value:
	return _operational_state


func get_security_state() -> SecurityState.Value:
	return _security_state


func get_occupant_count() -> int:
	return _occupant_count


func get_current_power_watts() -> float:
	return _current_power_watts


func get_updated_at_unix_ms() -> int:
	return _updated_at_unix_ms


func get_room_summaries() -> Array[RoomSummary]:
	return _room_summaries.duplicate()


## Updates the aggregated home snapshot.
func update_snapshot(
	operational_state: HomeOperationalState.Value,
	security_state: SecurityState.Value,
	occupant_count: int,
	current_power_watts: float,
	room_summaries: Array[RoomSummary]
) -> Result:
	if occupant_count < 0:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Home occupant count cannot be negative."
			)
		)

	if current_power_watts < 0.0:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Home power consumption cannot be negative."
			)
		)

	var previous_operational_state := _operational_state
	var previous_security_state := _security_state

	_operational_state = operational_state
	_security_state = security_state
	_occupant_count = occupant_count
	_current_power_watts = current_power_watts
	_room_summaries = room_summaries.duplicate()
	_updated_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)

	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_UPDATED,
			{
				&"home_id": get_id().as_string(),
				&"operational_state":
					HomeOperationalState.to_string_name(
						_operational_state
					),
				&"security_state":
					SecurityState.to_label(_security_state),
				&"occupant_count": _occupant_count,
				&"current_power_watts": _current_power_watts,
				&"room_count": _room_summaries.size(),
			}
		)
	)

	if previous_operational_state != _operational_state:
		_record_domain_event(
			DomainEvent.new(
				EVENT_STATE_CHANGED,
				{
					&"home_id": get_id().as_string(),
					&"previous_state":
						HomeOperationalState.to_string_name(
							previous_operational_state
						),
					&"current_state":
						HomeOperationalState.to_string_name(
							_operational_state
						),
				}
			)
		)

	if previous_security_state != _security_state:
		_record_domain_event(
			DomainEvent.new(
				EVENT_SECURITY_CHANGED,
				{
					&"home_id": get_id().as_string(),
					&"previous_state":
						SecurityState.to_label(
							previous_security_state
						),
					&"current_state":
						SecurityState.to_label(
							_security_state
						),
				}
			)
		)

	return Result.success()

#endregion