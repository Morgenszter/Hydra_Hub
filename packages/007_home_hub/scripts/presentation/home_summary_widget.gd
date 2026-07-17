class_name HomeSummaryWidget
extends WidgetBase
## Displays high-level home operational metrics.


#region Nodes

@onready var _home_name: RichTextLabel = %HomeName
@onready var _operational_state: RichTextLabel = %OperationalState
@onready var _security_state: RichTextLabel = %SecurityState
@onready var _occupancy_value: RichTextLabel = %OccupancyValue
@onready var _power_value: RichTextLabel = %PowerValue
@onready var _state_indicator: ColorRect = %StateIndicator

#endregion


#region Public API

## Applies a home overview snapshot.
func apply_overview(overview: HomeOverview) -> void:
	if overview == null or not is_node_ready():
		return

	var state := overview.get_operational_state()

	_home_name.text = overview.get_display_name()
	_operational_state.text = (
		"STATUS  //  %s"
		% String(
			HomeOperationalState.to_string_name(state)
		).to_upper()
	)
	_security_state.text = (
		"SECURITY  //  %s"
		% SecurityState.to_label(
			overview.get_security_state()
		)
	)
	_occupancy_value.text = str(
		overview.get_occupant_count()
	)
	_power_value.text = "%0.2f kW" % (
		overview.get_current_power_watts() / 1000.0
	)
	_state_indicator.color = HomeOperationalState.to_color(state)

#endregion