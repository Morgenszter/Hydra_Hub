class_name PluginManifestTest
extends RefCounted
## Provides PluginManifest validation tests.


#region Tests

static func run() -> void:
	var manifest := PluginManifest.new()

	assert(manifest.validate().is_failure())

	manifest.plugin_id = &"test_plugin"
	manifest.display_name = "TEST PLUGIN"
	manifest.version = "0.1.0"
	manifest.entry_script_path = "res://test_plugin.gd"

	assert(manifest.validate().is_success())

#endregion