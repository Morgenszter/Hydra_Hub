class_name RoomSummaryWidget
extends WidgetBase
## Displays one immutable room summary.


#region Nodes

@onready var _room_name: RichTextLabel = %RoomName
@onready var _occupancy: RichTextLabel = %Occupancy
@onready var _temperature: RichTextLabel = %Temperature
@onready var _device_count: RichTextLabel = %DeviceCount
@onready var _alert_indicator: ColorRect = %AlertIndicator

#endregion


#region Public API

## Applies a room summary snapshot.
func apply_summary(summary: RoomSummary) -> void:
	if summary == null or not is_node_ready():
		return

	_room_name.text = summary.get_display_name()
	_occupancy.text = (
		"OCCUPIED"
		if summary.is_occupied()
		else "VACANT"
	)
	_temperature.text = "%0.1f Â°C" % (
		summary.get_temperature_celsius()
	)
	_device_count.text = (
		"%d ACTIVE DEVICES"
		% summary.get_active_device_count()
	)
	_alert_indicator.visible = summary.get_alert_count() > 0

#endregion