class_name BootLoaderServiceTest
extends RefCounted
## Provides Boot Loader service composition tests.


#region Tests

static func run() -> void:
	var service := BootLoaderService.new()
	var configuration := BootLoaderConfiguration.new()
	configuration.change_scene_after_completion = false

	assert(service.configure(configuration).is_success())

	var step := CallableBootStep.new(
		&"test",
		"TEST",
		10,
		true,
		func() -> Result:
			return Result.success()
	)

	assert(service.register_step(step).is_success())

#endregion