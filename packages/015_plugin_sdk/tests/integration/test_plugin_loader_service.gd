class_name PluginLoaderServiceTest
extends RefCounted
## Provides Plugin Loader composition tests.


#region Tests

static func run() -> void:
	var registry := PluginRegistry.new()
	var loader := PluginLoaderService.new()
	var plugin := ExampleHydraPlugin.new()
	var manifest := PluginManifest.new()

	manifest.plugin_id = &"test_plugin"
	manifest.display_name = "TEST PLUGIN"
	manifest.version = "0.1.0"
	manifest.entry_script_path = (
		"res://packages/015_plugin_sdk/demo/example_plugin.gd"
	)
	manifest.requested_capabilities = PackedStringArray(
		["diagnostic_probe"]
	)

	assert(loader.configure(registry).is_success())
	assert(loader.load_plugin(plugin, manifest).is_success())
	assert(
		plugin.get_state()
		== PluginLifecycleState.Value.RUNNING
	)

#endregion