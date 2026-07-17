class_name HudModuleDefinitionTest
extends RefCounted
## Provides HUD module validation tests.


#region Tests

static func run() -> void:
	var module := HudModuleDefinition.new()

	assert(module.validate().is_failure())

	module.route_id = &"test"
	module.display_name = "TEST"
	module.package_id = &"test_package"
	module.scene_path = "res://test_scene.tscn"

	assert(module.validate().is_success())

#endregion