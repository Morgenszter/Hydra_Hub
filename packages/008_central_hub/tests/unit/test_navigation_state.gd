class_name NavigationStateTest
extends RefCounted
## Provides NavigationState domain tests.


#region Tests

static func run() -> void:
	var navigation := NavigationState.new(
		EntityId.generate()
	)

	var route := HubRoute.new()
	route.route_id = &"test"
	route.package_id = &"test_package"
	route.display_name = "TEST"
	route.scene_path = "res://test_scene.tscn"

	assert(
		navigation.register_route(route).is_success()
	)
	assert(
		navigation.activate_route(&"test").is_success()
	)
	assert(
		navigation.get_active_route_id() == &"test"
	)
	assert(
		navigation.get_routes().size() == 1
	)
	assert(
		not navigation.pull_domain_events().is_empty()
	)

#endregion