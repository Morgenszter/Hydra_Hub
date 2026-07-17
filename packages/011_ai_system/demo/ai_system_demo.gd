class_name AiSystemDemo
extends Control
## Demonstrates AI System with the local development provider.


#region Nodes

@onready var _panel: AiConsolePanel = %AiConsolePanel

#endregion


#region State

var _service: AiSystemService
var _configuration: AiSystemConfiguration

#endregion


#region Lifecycle

func _ready() -> void:
	_service = AiSystemService.new()
	_service.name = "AiSystemService"
	add_child(_service)

	_configuration = AiSystemConfiguration.new()

	var configuration_result := _service.configure(
		_configuration
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	var provider := LocalDemoAiProvider.new()
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

	_service.create_conversation(
		"HYDRA LOCAL SESSION"
	)

#endregion