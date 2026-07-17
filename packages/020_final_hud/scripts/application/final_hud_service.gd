class_name FinalHudService
extends Node
## Coordinates Final HUD module registration and routing.


#region Signals

signal module_registered(module: HudModuleDefinition)
signal route_changed(
	module: HudModuleDefinition,
	previous_route_id: StringName
)
signal route_failed(
	route_id: StringName,
	error: DomainError
)
signal shell_lock_changed(locked: bool)

#endregion


#region State

var _configuration: FinalHudConfiguration
var _state: HudShellState
var _modules: Dictionary[StringName, HudModuleDefinition] = {}

#endregion


#region Public API

## Configures Final HUD.
func configure(
	configuration: FinalHudConfiguration
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Final HUD configuration cannot be null."
			)
		)

	_configuration = configuration
	_state = HudShellState.new(EntityId.generate())

	return Result.success()


## Registers one HUD module.
func register_module(
	module: HudModuleDefinition
) -> Result:
	if _state == null:
		return _not_configured()

	if module == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"HUD module cannot be null."
			)
		)

	var validation_result := module.validate()

	if validation_result.is_failure():
		return validation_result

	if _modules.has(module.route_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_ALREADY_REGISTERED,
				"HUD module is already registered.",
				{&"route_id": module.route_id}
			)
		)

	_modules[module.route_id] = module
	module_registered.emit(module)

	return Result.success(module)


## Registers multiple HUD modules.
func register_modules(
	modules: Array[HudModuleDefinition]
) -> Result:
	for module in modules:
		var result := register_module(module)

		if result.is_failure():
			return result

	return Result.success()


## Activates a registered module.
func activate_route(route_id: StringName) -> Result:
	if _state == null:
		return _not_configured()

	var module := _modules.get(
		route_id
	) as HudModuleDefinition

	if module == null:
		var missing_error := DomainError.new(
			HydraErrors.SERVICE_NOT_FOUND,
			"HUD route is not registered.",
			{&"route_id": route_id}
		)

		route_failed.emit(route_id, missing_error)

		return Result.failure(missing_error)

	if not module.enabled:
		var disabled_error := DomainError.new(
			HydraErrors.INVALID_STATE,
			"HUD module is disabled.",
			{&"route_id": route_id}
		)

		route_failed.emit(route_id, disabled_error)

		return Result.failure(disabled_error)

	if not ResourceLoader.exists(module.scene_path):
		var scene_error := DomainError.new(
			HydraErrors.INVALID_ARGUMENT,
			"HUD module scene does not exist.",
			{
				&"route_id": route_id,
				&"scene_path": module.scene_path,
			}
		)

		route_failed.emit(route_id, scene_error)

		return Result.failure(scene_error)

	var previous_route_id := _state.get_active_route_id()
	var state_result := _state.activate_route(route_id)

	if state_result.is_failure():
		route_failed.emit(
			route_id,
			state_result.get_error()
		)
		return state_result

	_publish_events()
	route_changed.emit(module, previous_route_id)

	return Result.success(module)


## Activates the configured default route.
func activate_default_route() -> Result:
	if _configuration == null:
		return _not_configured()

	return activate_route(
		_configuration.default_route_id
	)


## Locks or unlocks shell navigation.
func set_shell_locked(locked: bool) -> void:
	if _state == null:
		return

	_state.set_shell_locked(locked)
	_publish_events()
	shell_lock_changed.emit(locked)


## Returns sorted HUD modules.
func get_modules() -> Array[HudModuleDefinition]:
	var result: Array[HudModuleDefinition] = []

	for module: HudModuleDefinition in _modules.values():
		result.append(module)

	result.sort_custom(
		func(
			left: HudModuleDefinition,
			right: HudModuleDefinition
		) -> bool:
			return left.sort_order < right.sort_order
	)

	return result


## Returns the active route identifier.
func get_active_route_id() -> StringName:
	if _state == null:
		return &""

	return _state.get_active_route_id()

#endregion


#region Private methods

func _publish_events() -> void:
	if _state == null:
		return

	var events := _state.pull_domain_events()
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Final HUD service is not configured."
		)
	)

#endregion