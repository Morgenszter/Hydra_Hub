class_name AutomationDemo
extends Control
## Demonstrates Automation with local deterministic rules.


#region Nodes

@onready var _panel: AutomationPanel = %AutomationPanel

#endregion


#region State

var _service: AutomationService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = AutomationService.new()
	_service.name = "AutomationService"
	add_child(_service)

	var configuration := AutomationConfiguration.new()
	var repository := InMemoryAutomationRuleRepository.new()
	var executor := DemoAutomationActionExecutor.new()

	var configuration_result := _service.configure(
		configuration,
		repository
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	_service.register_executor(executor)
	_service.start()
	_panel.bind_service(_service)

	_register_demo_rules()

#endregion


#region Private methods

func _register_demo_rules() -> void:
	var temperature_rule := AutomationRule.new(
		EntityId.generate(),
		&"cool_server_room",
		"SERVER ROOM COOLING",
		"Increase cooling when server-room temperature is high.",
		AutomationTrigger.new(
			&"server_temperature_trigger",
			&"hydra.environment.zone.updated",
			{&"zone_id": &"server_room"}
		),
		[
			AutomationCondition.new(
				&"temperature_condition",
				&"temperature",
				AutomationOperator.Value.GREATER_THAN,
				26.0
			),
		],
		[
			AutomationAction.new(
				&"cooling_action",
				&"demo",
				&"increase_cooling",
				{
					&"device_id": &"server_fan",
					&"speed_percent": 90.0,
				}
			),
		],
		5.0
	)
	temperature_rule.enable()
	_service.register_rule(temperature_rule)

	var security_rule := AutomationRule.new(
		EntityId.generate(),
		&"security_alert",
		"SECURITY ALERT RESPONSE",
		"Activate tactical alert response after a security alarm.",
		AutomationTrigger.new(
			&"security_alarm_trigger",
			&"hydra.home.security.changed",
			{&"current_state": "ALARM"}
		),
		[],
		[
			AutomationAction.new(
				&"security_response_action",
				&"demo",
				&"activate_security_response",
				{&"priority": &"critical"},
				false
			),
		],
		10.0
	)
	security_rule.enable()
	_service.register_rule(security_rule)

	_panel.rebuild_rules()

#endregion