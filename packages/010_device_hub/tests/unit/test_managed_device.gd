class_name ManagedDeviceTest
extends RefCounted
## Provides ManagedDevice aggregate tests.


#region Tests

static func run() -> void:
	var descriptor := DeviceDescriptor.new(
		&"device_01",
		&"test_provider",
		"TEST DEVICE",
		"HYDRA",
		"TEST-01",
		&"office",
		[DeviceCapability.Value.POWER]
	)
	var device := ManagedDevice.new(
		EntityId.generate(),
		descriptor
	)
	var snapshot := DeviceStateSnapshot.new(
		&"device_01",
		DeviceConnectionState.Value.ONLINE,
		{&"power": true},
		1000
	)

	assert(device.update_state(snapshot).is_success())
	assert(device.get_state() == snapshot)
	assert(
		device.get_state().get_connection_state()
		== DeviceConnectionState.Value.ONLINE
	)
	assert(not device.pull_domain_events().is_empty())

#endregion