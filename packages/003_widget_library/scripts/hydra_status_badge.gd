class_name HydraStatusBadge
extends WidgetBase
## Displays a compact operational state.


#region State enumeration

enum Status {
	OFFLINE,
	STANDBY,
	ONLINE,
	WARNING,
	ERROR,
}

#endregion


#region Exported properties

@export var label: String = "SYSTEM"
@export var status: Status = Status.STANDBY

#endregion


#region Nodes

@onready var _indicator: ColorRect = %Indicator
@onready var _label: RichTextLabel = %Label

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	refresh()


func set_status(value: Status) -> void:
	status = value
	refresh()


func refresh() -> void:
	if not is_node_ready():
		return

	_label.text = "%s  //  %s" % [
		label,
		Status.keys()[status],
	]
	_indicator.color = _get_status_color()

#endregion


#region Private methods

func _get_status_color() -> Color:
	match status:
		Status.OFFLINE:
			return Color("#40515b")
		Status.STANDBY:
			return Color("#d6aa48")
		Status.ONLINE:
			return Color("#55f2a3")
		Status.WARNING:
			return Color("#ffbf47")
		Status.ERROR:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion