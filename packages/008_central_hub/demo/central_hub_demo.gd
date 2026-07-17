class_name CentralHubDemo
extends Control
## Demonstrates Central Hub route registration and activation.


#region Resources

const HOME_ROUTE: HubRoute = preload(
	"res://packages/008_central_hub/resources/routes/home_route.tres"
)
const VOICE_ROUTE: HubRoute = preload(
	"res://packages/008_central_hub/resources/routes/voice_route.tres"
)

#endregion


#region Nodes

@onready var _panel: CentralHubPanel = %CentralHubPanel

#endregion


#region State

var _service: CentralHubService
var _configuration: CentralHubConfiguration

#endregion


#region Lifecycle

func _ready() -> void:
	_service = CentralHubService.new()
	_service.name = "CentralHubService"
	add_child(_service)

	_configuration = CentralHubConfiguration.new()

	var configuration_result := _service.configure(
		_configuration
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	_panel.bind_service(
		_service,
		_configuration
	)

	var registration_result := _service.register_routes(
		[
			HOME_ROUTE,
			VOICE_ROUTE,
		]
	)

	if registration_result.is_failure():
		push_error(
			registration_result.get_error().get_message()
		)
		return

	_service.activate_default_route()

#endregion