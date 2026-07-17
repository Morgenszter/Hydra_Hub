class_name CentralHubPanel
extends PanelBase
## Primary HYDRA module-navigation panel.


#region Constants

const LAUNCHER_START_X: float = 60.0
const LAUNCHER_START_Y: float = 170.0

#endregion


#region Nodes

@onready var _launcher_layer: Control = %LauncherLayer
@onready var _active_route_label: RichTextLabel = %ActiveRouteLabel
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: CentralHubService
var _configuration: CentralHubConfiguration
var _launcher_scene: PackedScene = preload(
	"res://packages/008_central_hub/scenes/module_launcher_widget.tscn"
)

#endregion


#region Public API

## Binds the panel to Central Hub.
func bind_service(
	service: CentralHubService,
	configuration: CentralHubConfiguration
) -> void:
	assert(service != null, "Central Hub service cannot be null.")
	assert(
		configuration != null,
		"Central Hub configuration cannot be null."
	)

	_disconnect_service()

	_service = service
	_configuration = configuration

	_service.route_registered.connect(_on_route_registered)
	_service.route_activated.connect(_on_route_activated)
	_service.route_activation_failed.connect(
		_on_route_activation_failed
	)

	rebuild_launchers()


## Rebuilds all module launchers.
func rebuild_launchers() -> void:
	if _service == null or _configuration == null:
		return

	for child in _launcher_layer.get_children():
		child.queue_free()

	var routes := _service.get_routes(
		_configuration.show_disabled_routes
	)

	for index in routes.size():
		var route := routes[index]

		if (
			not route.enabled
			and not _configuration.show_disabled_routes
		):
			continue

		var launcher := (
			_launcher_scene.instantiate()
			as ModuleLauncherWidget
		)

		var column := index % _configuration.launcher_columns
		var row := index / _configuration.launcher_columns

		launcher.position = Vector2(
			LAUNCHER_START_X + (
				column * (
					_configuration.launcher_width
					+ _configuration.launcher_horizontal_gap
				)
			),
			LAUNCHER_START_Y + (
				row * (
					_configuration.launcher_height
					+ _configuration.launcher_vertical_gap
				)
			)
		)
		launcher.size = Vector2(
			_configuration.launcher_width,
			_configuration.launcher_height
		)

		_launcher_layer.add_child(launcher)
		launcher.apply_route(route)
		launcher.route_requested.connect(
			_on_route_requested
		)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.route_registered.is_connected(
		_on_route_registered
	):
		_service.route_registered.disconnect(
			_on_route_registered
		)

	if _service.route_activated.is_connected(
		_on_route_activated
	):
		_service.route_activated.disconnect(
			_on_route_activated
		)

	if _service.route_activation_failed.is_connected(
		_on_route_activation_failed
	):
		_service.route_activation_failed.disconnect(
			_on_route_activation_failed
		)


func _on_route_requested(route_id: StringName) -> void:
	if _service == null:
		return

	_service.activate_route(route_id)


func _on_route_registered(_route: HubRoute) -> void:
	rebuild_launchers()


func _on_route_activated(route: HubRoute) -> void:
	_error_label.visible = false
	_active_route_label.text = (
		"ACTIVE MODULE  //  %s"
		% route.display_name
	)


func _on_route_activation_failed(
	error: DomainError
) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]NAVIGATION FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()

#endregion