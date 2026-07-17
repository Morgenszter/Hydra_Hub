class_name CentralHubService
extends Node
## Coordinates route registration and navigation requests.


#region Signals

signal route_registered(route: HubRoute)
signal route_activated(route: HubRoute)
signal route_activation_failed(error: DomainError)

#endregion


#region State

var _configuration: CentralHubConfiguration
var _navigation: NavigationState
var _initialized: bool = false

#endregion


#region Public API

## Configures the Central Hub service.
func configure(
	configuration: CentralHubConfiguration
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Central Hub configuration cannot be null."
			)
		)

	if configuration.launcher_columns <= 0:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Central Hub launcher_columns must be positive."
			)
		)

	_configuration = configuration
	_navigation = NavigationState.new(EntityId.generate())
	_initialized = true

	return Result.success()


## Registers one route.
func register_route(route: HubRoute) -> Result:
	if not _initialized:
		return _not_initialized()

	var result := _navigation.register_route(route)

	if result.is_failure():
		return result

	_publish_events()
	route_registered.emit(route)

	return Result.success(route)


## Registers multiple routes.
func register_routes(routes: Array[HubRoute]) -> Result:
	for route in routes:
		var result := register_route(route)

		if result.is_failure():
			return result

	return Result.success()


## Activates a route.
func activate_route(route_id: StringName) -> Result:
	if not _initialized:
		return _not_initialized()

	var result := _navigation.activate_route(route_id)

	if result.is_failure():
		_publish_events()
		route_activation_failed.emit(result.get_error())
		return result

	var route: HubRoute = result.get_value()

	_publish_events()
	route_activated.emit(route)

	return Result.success(route)


## Activates the configured startup route.
func activate_default_route() -> Result:
	if not _initialized:
		return _not_initialized()

	return activate_route(
		_configuration.default_route_id
	)


## Returns sorted routes.
func get_routes(
	include_hidden: bool = false
) -> Array[HubRoute]:
	if _navigation == null:
		return []

	return _navigation.get_routes(include_hidden)


## Returns the active route.
func get_active_route() -> HubRoute:
	if _navigation == null:
		return null

	return _navigation.get_route(
		_navigation.get_active_route_id()
	)

#endregion


#region Private methods

func _not_initialized() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Central Hub service is not configured."
		)
	)


func _publish_events() -> void:
	if _navigation == null:
		return

	var events := _navigation.pull_domain_events()
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)

#endregion