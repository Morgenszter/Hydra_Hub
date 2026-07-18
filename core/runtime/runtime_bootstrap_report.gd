class_name RuntimeBootstrapReport
extends RefCounted
## Creates a structured runtime bootstrap report.


#region Public API

## Creates a bootstrap report dictionary.
static func create(tree: SceneTree) -> Dictionary:
	var report: Dictionary[StringName, Variant] = {
		&"timestamp_unix_ms": int(
			Time.get_unix_time_from_system() * 1000.0
		),
		&"godot_version": Engine.get_version_info(),
		&"platform": OS.get_name(),
		&"debug_build": OS.is_debug_build(),
		&"services": {},
	}

	var service_names: PackedStringArray = [
		"EventBus",
		"ThemeManager",
		"AnimationManager",
		"FxController",
		"Diagnostics",
		"NotificationCenter",
		"DeviceHub",
		"AiSystem",
		"Automation",
		"DebugTools",
		"AndroidPlatform",
		"HydraRuntime",
	]

	var services: Dictionary[StringName, bool] = {}

	for service_name in service_names:
		services[StringName(service_name)] = (
			tree.root.get_node_or_null(
				NodePath(service_name)
			) != null
		)

	report[&"services"] = services

	return report

#endregion