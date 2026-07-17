class_name HomeHubService
extends Node
## Coordinates retrieval and publication of home overview state.


#region Signals

signal overview_updated(overview: HomeOverview)
signal refresh_failed(error: DomainError)

#endregion


#region State

var _configuration: HomeHubConfiguration
var _provider: HomeOverviewProviderPort
var _overview: HomeOverview
var _refresh_timer: Timer

#endregion


#region Lifecycle

func _ready() -> void:
	_refresh_timer = Timer.new()
	_refresh_timer.name = "HomeHubRefreshTimer"
	_refresh_timer.one_shot = false
	_refresh_timer.timeout.connect(_on_refresh_timeout)
	add_child(_refresh_timer)

#endregion


#region Public API

## Configures Home Hub.
func configure(
	configuration: HomeHubConfiguration,
	provider: HomeOverviewProviderPort
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Home Hub configuration cannot be null."
			)
		)

	if provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Home overview provider cannot be null."
			)
		)

	if configuration.home_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Home Hub configuration requires home_id."
			)
		)

	_configuration = configuration
	_provider = provider
	_overview = HomeOverview.new(
		EntityId.from_string(String(configuration.home_id)),
		configuration.display_name
	)

	_refresh_timer.wait_time = configuration.refresh_interval_seconds

	return Result.success()


## Starts automatic overview refresh.
func start() -> Result:
	if _configuration == null or _provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Home Hub is not configured."
			)
		)

	_refresh_timer.start()

	return refresh()


## Stops automatic overview refresh.
func stop() -> void:
	_refresh_timer.stop()


## Refreshes the current home overview.
func refresh() -> Result:
	if _configuration == null or _provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Home Hub is not configured."
			)
		)

	var provider_result := _provider.fetch_overview(
		_configuration.home_id
	)

	if provider_result.is_failure():
		refresh_failed.emit(provider_result.get_error())
		return provider_result

	var snapshot: Dictionary = provider_result.get_value()

	var update_result := _overview.update_snapshot(
		snapshot.get(
			&"operational_state",
			HomeOperationalState.Value.UNKNOWN
		),
		snapshot.get(
			&"security_state",
			SecurityState.Value.UNKNOWN
		),
		snapshot.get(&"occupant_count", 0),
		snapshot.get(&"current_power_watts", 0.0),
		snapshot.get(&"rooms", [])
	)

	if update_result.is_failure():
		refresh_failed.emit(update_result.get_error())
		return update_result

	_publish_domain_events()
	overview_updated.emit(_overview)

	return Result.success(_overview)


## Returns the current overview.
func get_overview() -> HomeOverview:
	return _overview

#endregion


#region Private methods

func _publish_domain_events() -> void:
	if _overview == null:
		return

	var events := _overview.pull_domain_events()

	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _on_refresh_timeout() -> void:
	refresh()

#endregion