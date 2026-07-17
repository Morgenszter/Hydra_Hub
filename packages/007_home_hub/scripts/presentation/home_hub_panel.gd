class_name HomeHubPanel
extends PanelBase
## Main residential overview panel.


#region Constants

const ROOM_WIDGET_WIDTH: float = 360.0
const ROOM_WIDGET_HEIGHT: float = 148.0
const ROOM_COLUMN_GAP: float = 24.0
const ROOM_ROW_GAP: float = 20.0
const ROOM_START_X: float = 56.0
const ROOM_START_Y: float = 330.0
const ROOM_COLUMN_COUNT: int = 2

#endregion


#region Nodes

@onready var _summary_widget: HomeSummaryWidget = %HomeSummaryWidget
@onready var _rooms_layer: Control = %RoomsLayer
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: HomeHubService
var _room_scene: PackedScene = preload(
	"res://packages/007_home_hub/scenes/room_summary_widget.tscn"
)

#endregion


#region Public API

## Binds the panel to Home Hub.
func bind_service(service: HomeHubService) -> void:
	assert(service != null, "Home Hub service cannot be null.")

	_disconnect_service()
	_service = service

	_service.overview_updated.connect(_on_overview_updated)
	_service.refresh_failed.connect(_on_refresh_failed)


## Refreshes the bound service.
func refresh() -> Result:
	if _service == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Home Hub panel is not bound to a service."
			)
		)

	return _service.refresh()

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.overview_updated.is_connected(
		_on_overview_updated
	):
		_service.overview_updated.disconnect(
			_on_overview_updated
		)

	if _service.refresh_failed.is_connected(
		_on_refresh_failed
	):
		_service.refresh_failed.disconnect(
			_on_refresh_failed
		)


func _on_overview_updated(overview: HomeOverview) -> void:
	_error_label.visible = false
	_summary_widget.apply_overview(overview)
	_render_rooms(overview.get_room_summaries())


func _on_refresh_failed(error: DomainError) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]HOME HUB ERROR[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()


func _render_rooms(rooms: Array[RoomSummary]) -> void:
	for child in _rooms_layer.get_children():
		child.queue_free()

	for index in rooms.size():
		var widget := _room_scene.instantiate() as RoomSummaryWidget
		var column := index % ROOM_COLUMN_COUNT
		var row := index / ROOM_COLUMN_COUNT

		widget.position = Vector2(
			ROOM_START_X + (
				column * (ROOM_WIDGET_WIDTH + ROOM_COLUMN_GAP)
			),
			ROOM_START_Y + (
				row * (ROOM_WIDGET_HEIGHT + ROOM_ROW_GAP)
			)
		)
		widget.size = Vector2(
			ROOM_WIDGET_WIDTH,
			ROOM_WIDGET_HEIGHT
		)

		_rooms_layer.add_child(widget)
		widget.apply_summary(rooms[index])

#endregion