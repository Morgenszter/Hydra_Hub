class_name BootSequenceTest
extends RefCounted
## Provides BootSequence domain tests.


#region Tests

static func run() -> void:
	var sequence := BootSequence.new(
		EntityId.generate()
	)
	var step := CallableBootStep.new(
		&"test_step",
		"TEST STEP",
		10,
		true,
		func() -> Result:
			return Result.success()
	)

	assert(sequence.register_step(step).is_success())
	assert(sequence.validate_sequence().is_success())
	assert(sequence.start().is_success())
	assert(sequence.start_step(0).is_success())

	sequence.complete_step(step)

	assert(sequence.get_completed_step_count() == 1)
	assert(is_equal_approx(sequence.get_progress(), 1.0))
	assert(sequence.complete().is_success())

#endregion