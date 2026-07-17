class_name EnvironmentHubDemo
extends Control
## Demonstrates Environment Hub with deterministic local readings.


#region Nodes

@onready var _panel: EnvironmentHubPanel = %EnvironmentHubPanel

#endregion


#region State

var _service: EnvironmentHubService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = EnvironmentHubService.new()
	_service.name = "EnvironmentHubService"
	add_child(_service)

	var configuration: EnvironmentHubConfiguration = preload(
		"res://packages/009_environment_hub/resources/default_environment_hub_configuration.tres"
	)
	var provider := DemoEnvironmentProvider.new()

	var configuration_result := _service.configure(
		configuration,
		provider
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	_panel.bind_service(_service)
	_service.start()

#endregion