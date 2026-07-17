class_name PluginSdkDemo
extends Control
## Demonstrates plugin validation, registration and startup.


#region Nodes

@onready var _status_label: RichTextLabel = %StatusLabel

#endregion


#region State

var _loader: PluginLoaderService
var _registry: PluginRegistry

#endregion


#region Lifecycle

func _ready() -> void:
	_registry = PluginRegistry.new()
	_loader = PluginLoaderService.new()
	_loader.name = "PluginLoaderService"
	add_child(_loader)

	_loader.configure(_registry)
	_loader.plugin_started.connect(_on_plugin_started)
	_loader.plugin_failed.connect(_on_plugin_failed)

	var plugin := ExampleHydraPlugin.new()
	var manifest: PluginManifest = preload(
		"res://packages/015_plugin_sdk/demo/example_plugin_manifest.tres"
	)

	var result := _loader.load_plugin(plugin, manifest)

	if result.is_failure():
		_on_plugin_failed(
			manifest.plugin_id,
			result.get_error()
		)

#endregion


#region Event handlers

func _on_plugin_started(plugin: HydraPlugin) -> void:
	_status_label.text = (
		"[color=#55f2a3]PLUGIN ONLINE[/color]\n"
		+ "[color=#32d8ff]%s  //  VERSION %s[/color]"
	) % [
		plugin.get_manifest().display_name,
		plugin.get_manifest().version,
	]


func _on_plugin_failed(
	plugin_id: StringName,
	error: DomainError
) -> void:
	_status_label.text = (
		"[color=#ff4f62]PLUGIN FAILURE  //  %s[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % [
		String(plugin_id).to_upper(),
		error.get_message(),
	]

#endregion