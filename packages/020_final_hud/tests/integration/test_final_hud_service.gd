class_name FinalHudServiceTest
extends RefCounted
## Provides Final HUD service composition tests.


#region Tests

static func run() -> void:
	var service := FinalHudService.new()
	var configuration := FinalHudConfiguration.new()

	assert(service.configure(configuration).is_success())

	var module := HudModuleDefinition.new()
	module.route_id = &"test"
	module.display_name = "TEST"
	module.package_id = &"test_package"
	module.scene_path = (
		"res://packages/020_final_hud/demo/final_hud_demo.tscn"
	)

	assert(service.register_module(module).is_success())

#endregion