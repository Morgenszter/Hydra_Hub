class_name DeviceDescriptorTest
extends RefCounted
## Provides DeviceDescriptor value-object tests.


#region Tests

static func run() -> void:
	var descriptor := DeviceDescriptor.new(
		&"device_01",
		&"test_provider",
		"TEST DEVICE",
		"HYDRA",
		"TEST-01",
		&"office",
		[
			DeviceCapability.Value.POWER,
			DeviceCapability.Value.DIMMER,
		]
	)

	assert(descriptor.get_device_id() == &"device_01")
	assert(descriptor.get_provider_id() == &"test_provider")
	assert(descriptor.get_display_name() == "TEST DEVICE")
	assert(
		descriptor.has_capability(
			DeviceCapability.Value.POWER
		)
	)
	assert(
		not descriptor.has_capability(
			DeviceCapability.Value.CAMERA
		)
	)

#endregion