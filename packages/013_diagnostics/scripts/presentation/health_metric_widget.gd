class_name HealthMetricWidget
extends WidgetBase
## Displays one diagnostic finding.


#region Nodes

@onready var _indicator: ColorRect = %Indicator
@onready var _title_label: RichTextLabel = %TitleLabel
@onready var _message_label: RichTextLabel = %MessageLabel
@onready var _severity_label: RichTextLabel = %SeverityLabel

#endregion


#region Public API

## Applies one diagnostic finding.
func apply_finding(
	finding: DiagnosticFinding
) -> void:
	assert(
		finding != null,
		"HealthMetricWidget requires a finding."
	)

	if not is_node_ready():
		return

	_indicator.color = DiagnosticSeverity.to_color(
		finding.get_severity()
	)
	_title_label.text = finding.get_title()
	_message_label.text = finding.get_message()
	_severity_label.text = String(
		DiagnosticSeverity.to_string_name(
			finding.get_severity()
		)
	).to_upper()

#endregion