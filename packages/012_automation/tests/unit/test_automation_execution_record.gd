class_name AutomationExecutionRecordTest
extends RefCounted
## Provides AutomationExecutionRecord tests.


#region Tests

static func run() -> void:
	var record := AutomationExecutionRecord.new(
		&"execution_01",
		&"rule_01",
		1000
	)

	assert(
		record.get_state()
		== AutomationExecutionState.Value.QUEUED
	)

	record.mark_running()
	record.mark_action_completed()
	record.mark_succeeded()

	assert(
		record.get_state()
		== AutomationExecutionState.Value.SUCCEEDED
	)
	assert(record.get_completed_action_count() == 1)
	assert(record.get_completed_at_unix_ms() > 0)

#endregion