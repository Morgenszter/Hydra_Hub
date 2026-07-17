class_name AutomationPanel
extends PanelBase
## Main Automation management panel.


#region Constants

const CARD_WIDTH: float = 430.0
const CARD_HEIGHT: float = 170.0
const CARD_START_X: float = 54.0
const CARD_START_Y: float = 184.0
const CARD_HORIZONTAL_GAP: float = 24.0
const CARD_VERTICAL_GAP: float = 20.0
const CARD_COLUMNS: int = 2

#endregion


#region Nodes

@onready var _rule_layer: Control = %RuleLayer
@onready var _summary_label: RichTextLabel = %SummaryLabel
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: AutomationService
var _rule_card_scene: PackedScene = preload(
	"res://packages/012_automation/scenes/automation_rule_card.tscn"
)

#endregion


#region Public API

## Binds the panel to Automation.
func bind_service(service: AutomationService) -> void:
	assert(service != null, "Automation service cannot be null.")

	_disconnect_service()
	_service = service

	_service.rule_registered.connect(_on_rule_registered)
	_service.rule_updated.connect(_on_rule_updated)
	_service.execution_completed.connect(_on_execution_completed)
	_service.execution_failed.connect(_on_execution_failed)
	_service.operation_failed.connect(_on_operation_failed)

	rebuild_rules()


## Rebuilds visible rule cards.
func rebuild_rules() -> void:
	if _service == null:
		return

	var rules := _service.get_rules()

	for child in _rule_layer.get_children():
		child.queue_free()

	for index in rules.size():
		var card := (
			_rule_card_scene.instantiate()
			as AutomationRuleCard
		)
		var column := index % CARD_COLUMNS
		var row := index / CARD_COLUMNS

		card.position = Vector2(
			CARD_START_X + (
				column * (
					CARD_WIDTH + CARD_HORIZONTAL_GAP
				)
			),
			CARD_START_Y + (
				row * (
					CARD_HEIGHT + CARD_VERTICAL_GAP
				)
			)
		)
		card.size = Vector2(CARD_WIDTH, CARD_HEIGHT)

		_rule_layer.add_child(card)
		card.apply_rule(rules[index])
		card.toggle_requested.connect(_on_toggle_requested)
		card.execute_requested.connect(_on_execute_requested)

	_update_summary(rules)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.rule_registered.is_connected(_on_rule_registered):
		_service.rule_registered.disconnect(_on_rule_registered)

	if _service.rule_updated.is_connected(_on_rule_updated):
		_service.rule_updated.disconnect(_on_rule_updated)

	if _service.execution_completed.is_connected(
		_on_execution_completed
	):
		_service.execution_completed.disconnect(
			_on_execution_completed
		)

	if _service.execution_failed.is_connected(
		_on_execution_failed
	):
		_service.execution_failed.disconnect(
			_on_execution_failed
		)

	if _service.operation_failed.is_connected(
		_on_operation_failed
	):
		_service.operation_failed.disconnect(
			_on_operation_failed
		)


func _update_summary(
	rules: Array[AutomationRule]
) -> void:
	var enabled_count := 0
	var failed_count := 0

	for rule in rules:
		if rule.get_state() == AutomationRuleState.Value.ENABLED:
			enabled_count += 1
		elif rule.get_state() == AutomationRuleState.Value.FAILED:
			failed_count += 1

	_summary_label.text = (
		"RULES  //  %d    ENABLED  //  %d    FAILED  //  %d"
		% [
			rules.size(),
			enabled_count,
			failed_count,
		]
	)


func _on_toggle_requested(rule_id: StringName) -> void:
	if _service == null:
		return

	for rule in _service.get_rules():
		if rule.get_rule_id() != rule_id:
			continue

		if rule.get_state() == AutomationRuleState.Value.ENABLED:
			rule.disable()
		else:
			rule.enable()

		rebuild_rules()
		return


func _on_execute_requested(rule_id: StringName) -> void:
	if _service == null:
		return

	for rule in _service.get_rules():
		if rule.get_rule_id() != rule_id:
			continue

		var context := AutomationExecutionContext.new(
			rule_id,
			null,
			{&"manual": true}
		)
		var result := _service.execute_rule(rule, context)

		if result.is_failure():
			_on_operation_failed(result.get_error())

		return


func _on_rule_registered(
	_rule: AutomationRule
) -> void:
	rebuild_rules()


func _on_rule_updated(
	_rule: AutomationRule
) -> void:
	rebuild_rules()


func _on_execution_completed(
	_rule: AutomationRule,
	_record: AutomationExecutionRecord
) -> void:
	_error_label.visible = false
	rebuild_rules()


func _on_execution_failed(
	_rule: AutomationRule,
	record: AutomationExecutionRecord
) -> void:
	if record.get_error() != null:
		_on_operation_failed(record.get_error())


func _on_operation_failed(error: DomainError) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]AUTOMATION FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()

#endregion