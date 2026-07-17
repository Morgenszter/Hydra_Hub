class_name NullAndroidAdapterTest
extends RefCounted
## Provides desktop-safe Android adapter tests.


#region Tests

static func run() -> void:
	var adapter := NullAndroidPlatformAdapter.new()
	var result := adapter.get_platform_info()

	assert(result.is_success())
	assert(not adapter.is_android_runtime())
	assert(adapter.vibrate(100).is_failure())

#endregion