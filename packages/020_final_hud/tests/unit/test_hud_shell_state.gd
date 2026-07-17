class_name HudShellStateTest
extends RefCounted
## Provides HudShellState tests.


#region Tests

static func run() -> void:
	var state := HudShellState.new(
		EntityId.generate()
	)

	assert(state.activate_route(&"home").is_success())
	assert(state.get_active_route_id() == &"home")

	state.set_shell_locked(true)

	assert(state.is_shell_locked())
	assert(state.activate_route(&"ai").is_failure())

#endregion