class_name FoundationResultTest
extends RefCounted
## Provides executable Result smoke tests.


#region Tests

static func run() -> void:
	var success_result := Result.success(42)
	assert(success_result.is_success())
	assert(success_result.get_value() == 42)

	var error := DomainError.new(
		HydraErrors.UNKNOWN,
		"Expected failure."
	)
	var failure_result := Result.failure(error)
	assert(failure_result.is_failure())
	assert(failure_result.get_error() == error)

#endregion