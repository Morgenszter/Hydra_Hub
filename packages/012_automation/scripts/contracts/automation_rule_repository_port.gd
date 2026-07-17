@abstract
class_name AutomationRuleRepositoryPort
extends RefCounted
## Defines persistence operations for automation rules.


#region Public API

@abstract
func save(rule: AutomationRule) -> Result


@abstract
func remove(rule_id: StringName) -> Result


@abstract
func find_by_id(rule_id: StringName) -> Result


@abstract
func find_all() -> Result

#endregion