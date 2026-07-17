class_name AndroidDemo
extends Control
## Demonstrates platform-safe Android composition.


#region Nodes

@onready var _panel: AndroidStatusPanel = %AndroidStatusPanel

#endregion


#region State

var _service: AndroidPlatformService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = AndroidPlatformService.new()
	_service.name = "AndroidPlatformService"
	add_child(_service)

	var configuration := AndroidConfiguration.new()
	var adapter: AndroidPlatformPort

	if OS.get_name() == "Android":
		adapter = AndroidRuntimeAdapter.new()
	else:
		adapter = NullAndroidPlatformAdapter.new()

	var result := _service.configure(
		configuration,
		adapter
	)

	if result.is_failure():
		push_error(result.get_error().get_message())
		return

	_panel.bind_service(_service)
	_service.initialize_platform()

#endregion