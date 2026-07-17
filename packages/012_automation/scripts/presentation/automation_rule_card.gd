class_name AutomationRuleCard
extends WidgetBase
## Displays one automation rule and exposes a state toggle.


#region Signals

signal toggle_requested(rule_id: StringName)
signal execute_requested(rule_id: StringName)

#endregion


#region Nodes

@onready var _indicator: ColorRect = %Indicator
@onready var _name_label: RichTextLabel = %NameLabel
@onready var _description_label: RichTextLabel = %DescriptionLabel
@onready var _state_label: RichTextLabel = %StateLabel
@onready var _trigger_label: RichTextLabel = %TriggerLabel
@onready var _stats_label: RichTextLabel = %StatsLabel

#endregion


#region State

var _rule: AutomationRule

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	if _rule == null:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if not mouse_event.pressed:
			return

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			toggle_requested.emit(_rule.get_rule_id())
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			execute_requested.emit(_rule.get_rule_id())
			accept_event()

#endregion


#region Public API

## Applies an automation rule.
func apply_rule(rule: AutomationRule) -> void:
	assert(rule != null, "Automation rule card requires rule.")

	_rule = rule

	if not is_node_ready():
		return

	var state := rule.get_state()

	_indicator.color = AutomationRuleState.to_color(state)
	_name_label.text = rule.get_display_name()
	_description_label.text = rule.get_description()
	_state_label.text = String(
		AutomationRuleState.to_string_name(state)
	).to_upper()
	_trigger_label.text = (
		"TRIGGER  //  %s"
		% String(
			rule.get_trigger().get_event_name()
		).to_upper()
	)
	_stats_label.text = (
		"ACTIONS  //  %d    EXECUTIONS  //  %d"
		% [
			rule.get_actions().size(),
			rule.get_execution_count(),
		]
	)

#endregion