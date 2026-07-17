class_name BootLoaderService
extends Node
## Executes BootSequence and transitions to the target scene.


#region Signals

signal boot_started(sequence: BootSequence)
signal step_started(
	step: BootStep,
	index: int,
	total: int
)
signal step_completed(
	step: BootStep,
	progress: float
)
signal step_failed(
	step: BootStep,
	error: DomainError,
	critical: bool
)
signal boot_completed(sequence: BootSequence)
signal boot_failed(
	sequence: BootSequence,
	error: DomainError
)
signal scene_transition_started(scene_path: String)

#endregion


#region State

var _configuration: BootLoaderConfiguration
var _sequence: BootSequence
var _running: bool = false

#endregion


#region Public API

## Configures Boot Loader.
func configure(
	configuration: BootLoaderConfiguration
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Boot Loader configuration cannot be null."
			)
		)

	if configuration.target_scene_path.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Boot Loader target scene path cannot be empty."
			)
		)

	_configuration = configuration
	_sequence = BootSequence.new(EntityId.generate())

	return Result.success()


## Registers a boot step.
func register_step(step: BootStep) -> Result:
	if _sequence == null:
		return _not_configured()

	return _sequence.register_step(step)


## Starts the complete boot sequence.
func start_boot() -> Result:
	if _configuration == null or _sequence == null:
		return _not_configured()

	if _running:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Boot sequence is already running."
			)
		)

	var validation_result := _sequence.validate_sequence()

	if validation_result.is_failure():
		boot_failed.emit(
			_sequence,
			validation_result.get_error()
		)
		return validation_result

	var start_result := _sequence.start()

	if start_result.is_failure():
		return start_result

	_running = true
	boot_started.emit(_sequence)
	_publish_events()

	var steps := _sequence.get_steps()

	for index in steps.size():
		var step := steps[index]

		_sequence.start_step(index)
		_publish_events()
		step_started.emit(step, index, steps.size())

		var step_result := step.execute()

		if step_result.is_failure():
			step_failed.emit(
				step,
				step_result.get_error(),
				step.is_critical()
			)

			if (
				step.is_critical()
				and _configuration.stop_on_critical_failure
			):
				_sequence.fail(step_result.get_error())
				_publish_events()
				_running = false
				boot_failed.emit(
					_sequence,
					step_result.get_error()
				)

				return step_result

			_sequence.record_optional_failure(
				step,
				step_result.get_error()
			)
		else:
			_sequence.complete_step(step)

		_publish_events()
		step_completed.emit(
			step,
			_sequence.get_progress()
		)

		if _configuration.minimum_step_display_seconds > 0.0:
			await get_tree().create_timer(
				_configuration.minimum_step_display_seconds
			).timeout

	_sequence.complete()
	_publish_events()
	_running = false
	boot_completed.emit(_sequence)

	if _configuration.change_scene_after_completion:
		await get_tree().create_timer(
			_configuration.completion_delay_seconds
		).timeout

		return _transition_to_target_scene()

	return Result.success(_sequence)


## Returns current boot sequence.
func get_sequence() -> BootSequence:
	return _sequence

#endregion


#region Private methods

func _transition_to_target_scene() -> Result:
	var scene_path := _configuration.target_scene_path

	if not ResourceLoader.exists(scene_path):
		var error := DomainError.new(
			HydraErrors.INVALID_ARGUMENT,
			"Boot target scene does not exist.",
			{&"scene_path": scene_path}
		)

		boot_failed.emit(_sequence, error)

		return Result.failure(error)

	var transition_result := _sequence.transition()

	if transition_result.is_failure():
		return transition_result

	_publish_events()
	scene_transition_started.emit(scene_path)

	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		var scene_error := DomainError.new(
			HydraErrors.UNKNOWN,
			"Boot Loader failed to change scene.",
			{
				&"scene_path": scene_path,
				&"error": error,
			}
		)

		boot_failed.emit(_sequence, scene_error)

		return Result.failure(scene_error)

	return Result.success()


func _publish_events() -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	var events := _sequence.pull_domain_events()

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Boot Loader is not configured."
		)
	)

#endregion