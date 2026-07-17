class_name CentralHubServiceTest
extends RefCounted
## Provides Central Hub service composition tests.


#region Tests

static func run() -> void:
	var service := CentralHubService.new()
	var configuration := CentralHubConfiguration.new()

	assert(
		service.configure(configuration).is_success()
	)

	var route := HubRoute.new()
	route.route_id = &"home"
	route.package_id = &"007_home_hub"
	route.display_name = "HOME HUB"
	route.scene_path = (
		"res://packages/007_home_hub/scenes/home_hub_panel.tscn"
	)

	assert(service.register_route(route).is_success())
	assert(service.activate_route(&"home").is_success())
	assert(service.get_active_route() == route)

#endregion