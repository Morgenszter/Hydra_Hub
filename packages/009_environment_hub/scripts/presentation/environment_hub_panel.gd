class_name EnvironmentHubPanel
extends PanelBase
## Main environmental monitoring panel.


#region Constants

const ZONE_WIDGET_WIDTH: float = 382.0
const ZONE_WIDGET_HEIGHT: float = 188.0
const ZONE_COLUMN_GAP: float = 24.0
const ZONE_ROW_GAP: float = 20.0
const ZONE_START_X: float = 56.0
const ZONE_START_Y: float = 176.0
const ZONE_COLUMNS: int = 2

#endregion


#region Nodes

@onready var _zone_layer: Control = %ZoneLayer
@onready var _summary_label: RichTextLabel = %SummaryLabel
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: EnvironmentHubService
var _zone_scene: PackedScene = preload(
	"res://packages/009_environment_hub/scenes/environment_zone_widget.tscn"
)

#endregion


#region Public API

## Binds the panel to Environment Hub.
func bind_service(service: EnvironmentHubService) -> void:
	assert(service != null, "Environment Hub service cannot be null.")

	_disconnect_service()
	_service = service

	_service.zones_updated.connect(_on_zones_updated)
	_service.refresh_failed.connect(_on_refresh_failed)
	_service.critical_environment_detected.connect(
		_on_critical_environment_detected
	)


## Requests an immediate refresh.
func refresh() -> Result:
	if _service == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Environment Hub panel is not bound."
			)
		)

	return _service.refresh()

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.zones_updated.is_connected(_on_zones_updated):
		_service.zones_updated.disconnect(_on_zones_updated)

	if _service.refresh_failed.is_connected(_on_refresh_failed):
		_service.refresh_failed.disconnect(_on_refresh_failed)

	if _service.critical_environment_detected.is_connected(
		_on_critical_environment_detected
	):
		_service.critical_environment_detected.disconnect(
			_on_critical_environment_detected
		)


func _on_zones_updated(
	zones: Array[EnvironmentZone]
) -> void:
	_error_label.visible = false

	var warning_count := 0
	var critical_count := 0

	for zone in zones:
		match zone.get_alert_level():
			EnvironmentAlertLevel.Value.WARNING:
				warning_count += 1
			EnvironmentAlertLevel.Value.CRITICAL:
				critical_count += 1

	_summary_label.text = (
		"ZONES  //  %d    WARNINGS  //  %d    CRITICAL  //  %d"
		% [
			zones.size(),
			warning_count,
			critical_count,
		]
	)

	_render_zones(zones)


func _on_refresh_failed(error: DomainError) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]ENVIRONMENT HUB ERROR[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()


func _on_critical_environment_detected(
	zone: EnvironmentZone
) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]CRITICAL ENVIRONMENT[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % zone.get_display_name()


func _render_zones(
	zones: Array[EnvironmentZone]
) -> void:
	for child in _zone_layer.get_children():
		child.queue_free()

	for index in zones.size():
		var widget := (
			_zone_scene.instantiate()
			as EnvironmentZoneWidget
		)
		var column := index % ZONE_COLUMNS
		var row := index / ZONE_COLUMNS

		widget.position = Vector2(
			ZONE_START_X + (
				column * (
					ZONE_WIDGET_WIDTH + ZONE_COLUMN_GAP
				)
			),
			ZONE_START_Y + (
				row * (
					ZONE_WIDGET_HEIGHT + ZONE_ROW_GAP
				)
			)
		)
		widget.size = Vector2(
			ZONE_WIDGET_WIDTH,
			ZONE_WIDGET_HEIGHT
		)

		_zone_layer.add_child(widget)
		widget.apply_zone(zones[index])

#endregion