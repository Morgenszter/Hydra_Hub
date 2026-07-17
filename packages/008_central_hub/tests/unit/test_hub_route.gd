class_name HubRouteTest
extends RefCounted
## Provides HubRoute validation tests.


#region Tests

static func run() -> void:
	var invalid_route := HubRoute.new()
	assert(invalid_route.validate().is_failure())

	var valid_route := HubRoute.new()
	valid_route.route_id = &"home"
	valid_route.package_id = &"007_home_hub"
	valid_route.display_name = "HOME HUB"
	valid_route.scene_path = (
		"res://packages/007_home_hub/scenes/home_hub_panel.tscn"
	)

	assert(valid_route.validate().is_success())

#endregion