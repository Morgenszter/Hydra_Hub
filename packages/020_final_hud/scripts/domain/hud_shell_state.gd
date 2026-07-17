class_name HudShellState
extends AggregateRoot
## Owns active Final HUD route and shell state.


#region Events

const EVENT_ROUTE_CHANGED: StringName = \
	&"hydra.hud.route_changed"
const EVENT_SHELL_LOCK_CHANGED: StringName = \
	&"hydra.hud.shell_lock_changed"

#endregion


#region State

var _active_route_id: StringName = &""
var _previous_route_id: StringName = &""
var _shell_locked: bool = false

#endregion


#region Construction

func _init(id: EntityId) -> void:
	super(id)

#endregion


#region Public API

func get_active_route_id() -> StringName:
	return _active_route_id


func get_previous_route_id() -> StringName:
	return _previous_route_id


func is_shell_locked() -> bool:
	return _shell_locked


## Changes the active route.
func activate_route(route_id: StringName) -> Result:
	if route_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"HUD route identifier cannot be empty."
			)
		)

	if _shell_locked:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"HUD shell is locked."
			)
		)

	if _active_route_id == route_id:
		return Result.success()

	_previous_route_id = _active_route_id
	_active_route_id = route_id
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_ROUTE_CHANGED,
			{
				&"route_id": _active_route_id,
				&"previous_route_id": _previous_route_id,
			}
		)
	)

	return Result.success()


## Locks or unlocks route changes.
func set_shell_locked(locked: bool) -> void:
	if _shell_locked == locked:
		return

	_shell_locked = locked
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_SHELL_LOCK_CHANGED,
			{
				&"locked": _shell_locked,
			}
		)
	)

#endregion