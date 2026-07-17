class_name PluginRegistry
extends RefCounted
## Stores loaded plugins and exported extensions.


#region State

var _plugins: Dictionary[StringName, HydraPlugin] = {}
var _extensions: Dictionary[StringName, PluginExtensionDescriptor] = {}

#endregion


#region Public API

## Registers a plugin.
func register_plugin(
	plugin: HydraPlugin
) -> Result:
	if plugin == null or plugin.get_manifest() == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin and manifest are required."
			)
		)

	var plugin_id := plugin.get_manifest().plugin_id

	if _plugins.has(plugin_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Plugin is already registered.",
				{&"plugin_id": plugin_id}
			)
		)

	_plugins[plugin_id] = plugin

	return Result.success(plugin)


## Registers exported extensions.
func register_extensions(
	extensions: Array[PluginExtensionDescriptor]
) -> Result:
	for extension in extensions:
		var extension_id := extension.get_extension_id()

		if _extensions.has(extension_id):
			return Result.failure(
				DomainError.new(
					HydraErrors.INVALID_STATE,
					"Plugin extension is already registered.",
					{&"extension_id": extension_id}
				)
			)

		_extensions[extension_id] = extension

	return Result.success()


## Returns a plugin.
func get_plugin(plugin_id: StringName) -> HydraPlugin:
	return _plugins.get(plugin_id)


## Returns all plugins.
func get_plugins() -> Array[HydraPlugin]:
	var result: Array[HydraPlugin] = []

	for plugin: HydraPlugin in _plugins.values():
		result.append(plugin)

	return result


## Returns extensions for a capability.
func get_extensions_by_capability(
	capability: StringName
) -> Array[PluginExtensionDescriptor]:
	var result: Array[PluginExtensionDescriptor] = []

	for extension: PluginExtensionDescriptor in _extensions.values():
		if extension.get_capability() == capability:
			result.append(extension)

	return result

#endregion