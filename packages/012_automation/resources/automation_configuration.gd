class_name AutomationConfiguration
extends Resource
## Stores runtime limits and behavior for Automation.


#region Runtime

@export_group("Runtime")
@export var enabled: bool = true
@export_range(1, 128, 1) var maximum_rules: int = 64
@export_range(1, 64, 1) var maximum_actions_per_rule: int = 16
@export_range(1, 16, 1) var maximum_recursion_depth: int = 4
@export_range(1, 32, 1) var maximum_concurrent_executions: int = 4

#endregion


#region Timing

@export_group("Timing")
@export_range(0.0, 86400.0, 0.5) var default_cooldown_seconds: float = 5.0
@export_range(0.1, 60.0, 0.1) var scheduler_tick_seconds: float = 1.0
@export_range(1.0, 3600.0, 1.0) var execution_timeout_seconds: float = 30.0

#endregion


#region History

@export_group("History")
@export_range(1, 10000, 1) var maximum_history_records: int = 500
@export var persist_history: bool = false

#endregion