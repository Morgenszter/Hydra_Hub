class_name HomeHubDemo
extends Control
## Demonstrates Home Hub with a deterministic local provider.


#region Nodes

@onready var _panel: HomeHubPanel = %HomeHubPanel

#endregion


#region State

var _service: HomeHubService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = HomeHubService.new()
	_service.name = "HomeHubService"
	add_child(_service)

	var configuration := HomeHubConfiguration.new()
	var provider := DemoHomeOverviewProvider.new()

	var result := _service.configure(
		configuration,
		provider
	)

	if result.is_failure():
		push_error(result.get_error().get_message())
		return

	_panel.bind_service(_service)
	_service.start()

#endregion