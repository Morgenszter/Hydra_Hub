class_name RuntimeSmokeTest
extends RefCounted
## Executes lightweight runtime composition checks.


#region Public API

## Returns Result containing all verified service identifiers.
static func run(tree: SceneTree) -> Result:
	if tree == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Runtime smoke test requires SceneTree."
			)
		)

	var required_services: PackedStringArray = [
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

	var verified := PackedStringArray()

	for service_name in required_services:
		var node := tree.root.get_node_or_null(
			NodePath(service_name)
		)

		if node == null:
			return Result.failure(
				DomainError.new(
					HydraErrors.SERVICE_NOT_FOUND,
					"Runtime smoke test failed.",
					{
						&"service_id": service_name,
					}
				)
			)

		verified.append(service_name)

	return Result.success(verified)

#endregion