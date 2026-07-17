class_name EnvironmentHubService
extends Node
## Coordinates environmental snapshot retrieval and publication.


#region Signals

signal zones_updated(zones: Array[EnvironmentZone])
signal refresh_failed(error: DomainError)
signal critical_environment_detected(zone: EnvironmentZone)

#endregion


#region State

var _configuration: EnvironmentHubConfiguration
var _provider: EnvironmentProviderPort
var _zones: Dictionary[StringName, EnvironmentZone] = {}
var _refresh_timer: Timer

#endregion


#region Lifecycle

func _ready() -> void:
	_refresh_timer = Timer.new()
	_refresh_timer.name = "EnvironmentRefreshTimer"
	_refresh_timer.one_shot = false
	_refresh_timer.timeout.connect(_on_refresh_timeout)
	add_child(_refresh_timer)

#endregion


#region Public API

## Configures Environment Hub.
func configure(
	configuration: EnvironmentHubConfiguration,
	provider: EnvironmentProviderPort
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Environment Hub configuration cannot be null."
			)
		)

	if provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Environment provider cannot be null."
			)
		)

	if configuration.thresholds == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Environment Hub requires thresholds."
			)
		)

	_configuration = configuration
	_provider = provider
	_refresh_timer.wait_time = configuration.refresh_interval_seconds

	return Result.success()


## Starts automatic refresh.
func start() -> Result:
	if _configuration == null or _provider == null:
		return _not_configured()

	if _configuration.automatic_refresh_enabled:
		_refresh_timer.start()

	return refresh()


## Stops automatic refresh.
func stop() -> void:
	_refresh_timer.stop()


## Refreshes all environmental zones.
func refresh() -> Result:
	if _configuration == null or _provider == null:
		return _not_configured()

	var provider_result := _provider.fetch_zones()

	if provider_result.is_failure():
		refresh_failed.emit(provider_result.get_error())
		return provider_result

	var snapshots: Array = provider_result.get_value()

	for snapshot: Dictionary in snapshots:
		var zone_id: StringName = snapshot.get(&"zone_id", &"")

		if zone_id.is_empty():
			continue

		var zone := _zones.get(zone_id) as EnvironmentZone

		if zone == null:
			zone = EnvironmentZone.new(
				EntityId.from_string(String(zone_id)),
				zone_id,
				snapshot.get(&"display_name", String(zone_id))
			)
			_zones[zone_id] = zone

		var readings: Array[EnvironmentReading] = []

		for reading in snapshot.get(&"readings", []):
			if reading is EnvironmentReading:
				readings.append(reading)

		var update_result := zone.update_readings(
			readings,
			_configuration.thresholds
		)

		if update_result.is_failure():
			refresh_failed.emit(update_result.get_error())
			return update_result

		_publish_zone_events(zone)

		if (
			zone.get_alert_level()
			== EnvironmentAlertLevel.Value.CRITICAL
		):
			critical_environment_detected.emit(zone)

	var zone_list := get_zones()
	zones_updated.emit(zone_list)

	return Result.success(zone_list)


## Returns all zones sorted by display name.
func get_zones() -> Array[EnvironmentZone]:
	var result: Array[EnvironmentZone] = []

	for zone: EnvironmentZone in _zones.values():
		result.append(zone)

	result.sort_custom(
		func(left: EnvironmentZone, right: EnvironmentZone) -> bool:
			return left.get_display_name() < right.get_display_name()
	)

	return result


## Returns a zone by identifier.
func get_zone(zone_id: StringName) -> EnvironmentZone:
	return _zones.get(zone_id)

#endregion


#region Private methods

func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Environment Hub is not configured."
		)
	)


func _publish_zone_events(zone: EnvironmentZone) -> void:
	var events := zone.pull_domain_events()
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _on_refresh_timeout() -> void:
	refresh()

#endregion