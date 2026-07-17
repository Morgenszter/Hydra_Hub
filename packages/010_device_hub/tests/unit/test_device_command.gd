class_name DeviceCommandTest
extends RefCounted
## Provides DeviceCommand tests.


#region Tests

static func run() -> void:
	var command := DeviceCommand.new(
		&"device_01",
		&"set_power",
		{&"enabled": true}
	)

	assert(not command.get_command_id().is_empty())
	assert(command.get_device_id() == &"device_01")
	assert(command.get_command_name() == &"set_power")
	assert(command.get_argument(&"enabled") == true)
	assert(not command.get_correlation_id().is_empty())

#endregion