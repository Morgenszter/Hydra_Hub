class_name DeviceHubDemo
extends Control
## Demonstrates Device Hub with deterministic local devices.


#region Nodes

@onready var _panel: DeviceHubPanel = %DeviceHubPanel

#endregion


#region State

var _service: DeviceHubService
var _configuration: DeviceHubConfiguration

#endregion


#region Lifecycle

func _ready() -> void:
	_service = DeviceHubService.new()
	_service.name = "DeviceHubService"
	add_child(_service)

	_configuration = DeviceHubConfiguration.new()

	var configuration_result := _service.configure(
		_configuration
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	var provider := DemoDeviceProvider.new()
	var provider_result := _service.register_provider(provider)

	if provider_result.is_failure():
		push_error(
			provider_result.get_error().get_message()
		)
		return

	_panel.bind_service(
		_service,
		_configuration
	)
	_service.start()

#endregion