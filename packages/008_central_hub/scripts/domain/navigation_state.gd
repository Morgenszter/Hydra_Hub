class_name NavigationState
extends AggregateRoot
## Owns Central Hub route registration and active-route state.


#region Events

const EVENT_ROUTE_REGISTERED: StringName = \
	&"hydra.central_hub.route.registered"
const EVENT_ROUTE_ACTIVATED: StringName = \
	&"hydra.central_hub.route.activated"
const EVENT_ROUTE_REJECTED: StringName = \
	&"hydra.central_hub.route.rejected"

#endregion


#region State

var _routes: Dictionary[StringName, HubRoute] = {}
var _active_route_id: StringName = &""
var _previous_route_id: StringName = &""

#endregion


#region Construction

func _init(id: EntityId) -> void:
	super(id)

#endregion


#region Public API

## Registers a validated route.
func register_route(route: HubRoute) -> Result:
	if route == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Central Hub route cannot be null."
			)
		)

	var validation_result := route.validate()

	if validation_result.is_failure():
		return validation_result

	if _routes.has(route.route_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Central Hub route is already registered.",
				{&"route_id": route.route_id}
			)
		)

	_routes[route.route_id] = route
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_ROUTE_REGISTERED,
			{
				&"route_id": route.route_id,
				&"package_id": route.package_id,
			}
		)
	)

	return Result.success()


## Activates a registered and enabled route.
func activate_route(route_id: StringName) -> Result:
	if not _routes.has(route_id):
		return _reject_route(
			route_id,
			"Central Hub route is not registered."
		)

	var route: HubRoute = _routes[route_id]

	if not route.enabled:
		return _reject_route(
			route_id,
			"Central Hub route is disabled."
		)

	if _active_route_id == route_id:
		return Result.success(route)

	_previous_route_id = _active_route_id
	_active_route_id = route_id
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_ROUTE_ACTIVATED,
			{
				&"route_id": route.route_id,
				&"package_id": route.package_id,
				&"scene_path": route.scene_path,
				&"previous_route_id": _previous_route_id,
			}
		)
	)

	return Result.success(route)


## Returns a registered route.
func get_route(route_id: StringName) -> HubRoute:
	return _routes.get(route_id)


## Returns all routes sorted by sort_order.
func get_routes(
	include_hidden: bool = false
) -> Array[HubRoute]:
	var result: Array[HubRoute] = []

	for route: HubRoute in _routes.values():
		if route.visible or include_hidden:
			result.append(route)

	result.sort_custom(
		func(left: HubRoute, right: HubRoute) -> bool:
			return left.sort_order < right.sort_order
	)

	return result


## Returns the active route identifier.
func get_active_route_id() -> StringName:
	return _active_route_id


## Returns the previous route identifier.
func get_previous_route_id() -> StringName:
	return _previous_route_id

#endregion


#region Private methods

func _reject_route(
	route_id: StringName,
	message: String
) -> Result:
	var error := DomainError.new(
		HydraErrors.INVALID_STATE,
		message,
		{&"route_id": route_id}
	)

	_record_domain_event(
		DomainEvent.new(
			EVENT_ROUTE_REJECTED,
			{
				&"route_id": route_id,
				&"error": error.to_dictionary(),
			}
		)
	)

	return Result.failure(error)

#endregion