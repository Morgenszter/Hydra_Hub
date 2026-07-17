class_name DiagnosticsDemo
extends Control
## Demonstrates Diagnostics with the runtime probe.


#region Nodes

@onready var _panel: DiagnosticsPanel = %DiagnosticsPanel

#endregion


#region State

var _service: DiagnosticsService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = DiagnosticsService.new()
	_service.name = "DiagnosticsService"
	add_child(_service)

	var configuration := DiagnosticsConfiguration.new()
	var probe := RuntimeDiagnosticProbe.new()

	var configuration_result := _service.configure(
		configuration
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	_service.register_probe(probe)
	_panel.bind_service(_service)
	_service.start()

#endregion