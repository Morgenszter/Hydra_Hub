class_name SystemStatusBar
extends WidgetBase
## Displays global HYDRA status information.


#region Nodes

@onready var _clock_label: RichTextLabel = %ClockLabel
@onready var _health_label: RichTextLabel = %HealthLabel
@onready var _route_label: RichTextLabel = %RouteLabel
@onready var _connection_label: RichTextLabel = %ConnectionLabel

#endregion


#region State

var _service: FinalHudService
var _clock_timer: Timer

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	_clock_timer = Timer.new()
	_clock_timer.name = "HudClockTimer"
	_clock_timer.wait_time = 1.0
	_clock_timer.one_shot = false
	_clock_timer.timeout.connect(_update_clock)
	add_child(_clock_timer)
	_clock_timer.start()

	_update_clock()


#region Public API

## Binds the status bar to FinalHudService.
func bind_service(service: FinalHudService) -> void:
	assert(service != null, "Final HUD service cannot be null.")

	_disconnect_service()
	_service = service
	_service.route_changed.connect(
		_on_route_changed
	)

#endregion


## Updates the system health display.
func set_health_state(
	state: SystemHealthState.Value
) -> void:
	_health_label.text = (
		"SYSTEM  //  %s"
		% String(
			SystemHealthState.to_string_name(state)
		).to_upper()
	)
	_health_label.modulate = SystemHealthState.to_color(state)


## Updates connection display.
func set_connection_state(
	label: String,
	online: bool
) -> void:
	_connection_label.text = (
		"LINK  //  %s"
		% label.to_upper()
	)
	_connection_label.modulate = (
		Color("#55f2a3")
		if online
		else Color("#ff4f62")
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.route_changed.is_connected(
		_on_route_changed
	):
		_service.route_changed.disconnect(
			_on_route_changed
		)


func _update_clock() -> void:
	var datetime := Time.get_datetime_dict_from_system()

	_clock_label.text = (
		"%04d-%02d-%02d  //  %02d:%02d:%02d"
		% [
			datetime.year,
			datetime.month,
			datetime.day,
			datetime.hour,
			datetime.minute,
			datetime.second,
		]
	)


func _on_route_changed(
	module: HudModuleDefinition,
	_previous_route_id: StringName
) -> void:
	_route_label.text = (
		"MODULE  //  %s"
		% module.display_name
	)

#endregion