class_name EnvironmentMetricWidget
extends WidgetBase
## Displays one normalized environmental reading.


#region Nodes

@onready var _metric_label: RichTextLabel = %MetricLabel
@onready var _value_label: RichTextLabel = %ValueLabel
@onready var _source_label: RichTextLabel = %SourceLabel

#endregion


#region Public API

## Applies an environmental reading.
func apply_reading(
	reading: EnvironmentReading,
	decimals: int = 1
) -> void:
	if reading == null or not is_node_ready():
		return

	var metric_name := String(
		EnvironmentMetricType.to_string_name(
			reading.get_metric_type()
		)
	).to_upper()

	_metric_label.text = metric_name

	if not reading.is_available():
		_value_label.text = "[color=#40515b]N/A[/color]"
	else:
		_value_label.text = (
			"[color=#32d8ff]%.*f %s[/color]"
			% [
				decimals,
				reading.get_value(),
				reading.get_unit(),
			]
		)

	_source_label.text = (
		"SOURCE  //  %s"
		% String(reading.get_source_id()).to_upper()
	)

#endregion