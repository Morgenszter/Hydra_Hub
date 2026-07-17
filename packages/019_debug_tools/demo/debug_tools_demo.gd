class_name DebugToolsDemo
extends Control
## Demonstrates Debug Tools runtime inspection.


#region Nodes

@onready var _console: DebugConsolePanel = %DebugConsolePanel
@onready var _overlay: PerformanceOverlay = %PerformanceOverlay

#endregion


#region State

var _service: DebugToolsService

#endregion


#region Lifecycle

func _ready() -> void:
	var configuration := DebugToolsConfiguration.new()
	var registry := DebugCommandRegistry.new()

	registry.register_command(
		HelpDebugCommand.new(registry)
	)
	registry.register_command(
		RuntimeDebugCommand.new()
	)
	registry.register_command(
		ClearDebugCommand.new()
	)

	_service = DebugToolsService.new()
	_service.name = "DebugToolsService"
	add_child(_service)

	_service.configure(
		configuration,
		registry
	)
	_service.start()

	_console.bind_service(_service)
	_overlay.bind_service(_service)

	_service.log(
		DebugLogLevel.Value.INFO,
		&"debug_tools",
		"Debug Tools initialized."
	)

#endregion