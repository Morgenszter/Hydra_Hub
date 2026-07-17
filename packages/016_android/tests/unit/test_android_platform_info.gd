class_name AndroidPlatformInfoTest
extends RefCounted
## Provides AndroidPlatformInfo tests.


#region Tests

static func run() -> void:
	var info := AndroidPlatformInfo.new(
		false,
		"Windows",
		"DESKTOP",
		0,
		{
			AndroidCapability.PLATFORM_RUNTIME: false,
		}
	)

	assert(not info.is_android())
	assert(info.get_operating_system_name() == "Windows")
	assert(
		not info.has_capability(
			AndroidCapability.PLATFORM_RUNTIME
		)
	)

#endregion