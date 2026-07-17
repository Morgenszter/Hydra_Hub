class_name EnvironmentZoneWidget
extends WidgetBase
## Displays one environmental zone and its key readings.


#region Nodes

@onready var _zone_name: RichTextLabel = %ZoneName
@onready var _alert_label: RichTextLabel = %AlertLabel
@onready var _alert_indicator: ColorRect = %AlertIndicator
@onready var _temperature: RichTextLabel = %Temperature
@onready var _humidity: RichTextLabel = %Humidity
@onready var _air_quality: RichTextLabel = %AirQuality

#endregion


#region Public API

## Applies a zone snapshot.
func apply_zone(zone: EnvironmentZone) -> void:
	if zone == null or not is_node_ready():
		return

	var alert_level := zone.get_alert_level()

	_zone_name.text = zone.get_display_name()
	_alert_label.text = EnvironmentAlertLevel.to_label(alert_level)
	_alert_indicator.color = EnvironmentAlertLevel.to_color(
		alert_level
	)

	_temperature.text = _format_reading(
		zone.get_reading(
			EnvironmentMetricType.Value.TEMPERATURE
		),
		1
	)
	_humidity.text = _format_reading(
		zone.get_reading(
			EnvironmentMetricType.Value.HUMIDITY
		),
		0
	)

	var air_reading := zone.get_reading(
		EnvironmentMetricType.Value.CO2
	)

	if air_reading == null:
		air_reading = zone.get_reading(
			EnvironmentMetricType.Value.PM25
		)

	_air_quality.text = _format_reading(air_reading, 0)

#endregion


#region Private methods

func _format_reading(
	reading: EnvironmentReading,
	decimals: int
) -> String:
	if reading == null or not reading.is_available():
		return "N/A"

	return "%.*f %s" % [
		decimals,
		reading.get_value(),
		reading.get_unit(),
	]

#endregion