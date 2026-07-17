class_name DebugCommandRegistryTest
extends RefCounted
## Provides DebugCommandRegistry tests.


#region Tests

static func run() -> void:
	var registry := DebugCommandRegistry.new()
	var runtime_command := RuntimeDebugCommand.new()

	assert(
		registry.register_command(
			runtime_command
		).is_success()
	)
	assert(
		registry.execute_line("runtime").is_success()
	)
	assert(
		registry.execute_line("unknown").is_failure()
	)

#endregion