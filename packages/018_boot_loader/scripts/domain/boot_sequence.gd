class_name BootSequence
extends AggregateRoot
## Owns ordered boot-step execution state.


#region Events

const EVENT_STATE_CHANGED: StringName = \
	&"hydra.boot.state_changed"
const EVENT_STEP_STARTED: StringName = \
	&"hydra.boot.step_started"
const EVENT_STEP_COMPLETED: StringName = \
	&"hydra.boot.step_completed"
const EVENT_STEP_FAILED: StringName = \
	&"hydra.boot.step_failed"

#endregion


#region State

var _steps: Array[BootStep] = []
var _state: BootState.Value = BootState.Value.IDLE
var _current_step_index: int = -1
var _completed_step_count: int = 0
var _failure: DomainError

#endregion


#region Construction

func _init(id: EntityId) -> void:
	super(id)

#endregion


#region Public API

func get_state() -> BootState.Value:
	return _state


func get_steps() -> Array[BootStep]:
	return _steps.duplicate()


func get_current_step_index() -> int:
	return _current_step_index


func get_completed_step_count() -> int:
	return _completed_step_count


func get_failure() -> DomainError:
	return _failure


func get_progress() -> float:
	if _steps.is_empty():
		return 1.0

	return float(_completed_step_count) / float(_steps.size())


func register_step(step: BootStep) -> Result:
	if _state != BootState.Value.IDLE:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Boot steps cannot be registered after startup."
			)
		)

	if step == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Boot step cannot be null."
			)
		)

	for existing_step in _steps:
		if existing_step.get_step_id() == step.get_step_id():
			return Result.failure(
				DomainError.new(
					HydraErrors.INVALID_STATE,
					"Boot step is already registered.",
					{&"step_id": step.get_step_id()}
				)
			)

	_steps.append(step)
	_steps.sort_custom(
		func(left: BootStep, right: BootStep) -> bool:
			return left.get_order() < right.get_order()
	)

	return Result.success()


func validate_sequence() -> Result:
	_state = BootState.Value.VALIDATING
	_record_state_event()

	if _steps.is_empty():
		return fail(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Boot sequence contains no steps."
			)
		)

	for step in _steps:
		var result := step.validate()

		if result.is_failure():
			return fail(result.get_error())

	_state = BootState.Value.IDLE
	_record_state_event()

	return Result.success()


func start() -> Result:
	if _state != BootState.Value.IDLE:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Boot sequence cannot start from current state."
			)
		)

	_state = BootState.Value.BOOTING
	_current_step_index = -1
	_completed_step_count = 0
	_failure = null
	_record_state_event()

	return Result.success()


func start_step(index: int) -> Result:
	if index < 0 or index >= _steps.size():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Boot step index is invalid."
			)
		)

	_current_step_index = index

	var step := _steps[index]

	_record_domain_event(
		DomainEvent.new(
			EVENT_STEP_STARTED,
			{
				&"step_id": step.get_step_id(),
				&"index": index,
			}
		)
	)

	return Result.success(step)


func complete_step(step: BootStep) -> void:
	_completed_step_count += 1
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_STEP_COMPLETED,
			{
				&"step_id": step.get_step_id(),
				&"completed": _completed_step_count,
				&"total": _steps.size(),
			}
		)
	)


func record_optional_failure(
	step: BootStep,
	error: DomainError
) -> void:
	_completed_step_count += 1

	_record_domain_event(
		DomainEvent.new(
			EVENT_STEP_FAILED,
			{
				&"step_id": step.get_step_id(),
				&"critical": false,
				&"error": error.to_dictionary(),
			}
		)
	)


func complete() -> Result:
	_state = BootState.Value.COMPLETED
	_record_state_event()

	return Result.success()


func transition() -> Result:
	if _state != BootState.Value.COMPLETED:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Boot sequence is not complete."
			)
		)

	_state = BootState.Value.TRANSITIONING
	_record_state_event()

	return Result.success()


func fail(error: DomainError) -> Result:
	_failure = error
	_state = BootState.Value.FAILED
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_STEP_FAILED,
			{
				&"critical": true,
				&"error": error.to_dictionary(),
			}
		)
	)

	_record_state_event()

	return Result.failure(error)

#endregion


#region Private methods

func _record_state_event() -> void:
	_record_domain_event(
		DomainEvent.new(
			EVENT_STATE_CHANGED,
			{
				&"state": BootState.to_string_name(_state),
				&"progress": get_progress(),
			}
		)
	)

#endregion