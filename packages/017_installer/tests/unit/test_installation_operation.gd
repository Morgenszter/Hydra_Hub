class_name InstallationOperationTest
extends RefCounted
## Provides installation operation validation tests.


#region Tests

static func run() -> void:
	var valid_operation := InstallationOperation.new(
		InstallationOperation.Type.WRITE_TEXT_FILE,
		"config/settings.cfg",
		"enabled=true"
	)

	assert(valid_operation.validate().is_success())

	var invalid_operation := InstallationOperation.new(
		InstallationOperation.Type.WRITE_TEXT_FILE,
		"../unsafe.txt",
		"unsafe"
	)

	assert(invalid_operation.validate().is_failure())

#endregion