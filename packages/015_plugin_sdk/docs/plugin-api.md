# Plugin API

A plugin extends HydraPlugin.

Required lifecycle:

- validate_manifest
- initialize_plugin
- start_plugin
- stop_plugin
- dispose_plugin

Plugins register extension descriptors through PluginContext.