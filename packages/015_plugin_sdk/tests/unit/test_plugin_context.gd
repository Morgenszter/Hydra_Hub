class_name PluginContextTest
extends RefCounted
## Provides PluginContext tests.


#region Tests

static func run() -> void:
	var context := PluginContext.new()
	var service := RefCounted.new()

	assert(
		context.grant_service(
			&"test_service",
			service
		).is_success()
	)
	assert(context.has_service(&"test_service"))
	assert(context.get_service(&"test_service") == service)

	var extension := PluginExtensionDescriptor.new(
		&"test_extension",
		PluginCapability.UI_WIDGET,
		service
	)

	assert(
		context.register_extension(extension).is_success()
	)
	assert(context.get_extensions().size() == 1)

#endregion