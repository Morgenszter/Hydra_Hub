class_name DebugLogEntryTest
extends RefCounted
## Provides DebugLogEntry tests.


#region Tests

static func run() -> void:
	var entry := DebugLogEntry.new(
		DebugLogLevel.Value.INFO,
		&"test",
		"Test message."
	)

	assert(entry.get_source() == &"test")
	assert(entry.get_message() == "Test message.")
	assert(
		entry.get_level()
		== DebugLogLevel.Value.INFO
	)

#endregion