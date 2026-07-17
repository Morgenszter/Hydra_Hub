class_name FinalHudShell
extends Control
## Production composition root for the HYDRA Final HUD.


#region Resources

@export var configuration: FinalHudConfiguration

#endregion


#region Nodes

@onready var _status_bar: SystemStatusBar = %SystemStatusBar
@onready var _navigation_rail: TacticalNavigationRail = %NavigationRail
@onready var _module_viewport: ModuleViewport = %ModuleViewport
@onready var _scanlines: ColorRect = %Scanlines
@onready var _vignette: ColorRect = %Vignette
@onready var _debug_overlay: Control = %DebugOverlay
@onready var _notification_output: RichTextLabel = %NotificationOutput

#endregion


#region State

var _service: FinalHudService

#endregion


#region Lifecycle

func _ready() -> void:
	if configuration == null:
		configuration = FinalHudConfiguration.new()

	_service = FinalHudService.new()
	_service.name = "FinalHudService"
	add_child(_service)

	var configuration_result := _service.configure(
		configuration
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	_status_bar.bind_service(_service)
	_navigation_rail.bind_service(_service)
	_module_viewport.bind_service(_service)

	_apply_effect_configuration()
	_register_default_modules()
	_bind_optional_services()

	var route_result := _service.activate_default_route()

	if route_result.is_failure():
		push_warning(
			route_result.get_error().get_message()
		)

#endregion


#region Private methods

func _register_default_modules() -> void:
	var modules: Array[HudModuleDefinition] = [
		_create_module(
			&"home",
			"HOME HUB",
			"HOME",
			&"007_home_hub",
			"res://packages/007_home_hub/scenes/home_hub_panel.tscn",
			10,
			Color("#32d8ff")
		),
		_create_module(
			&"voice",
			"VOICE HUB",
			"VOICE",
			&"006_voice_hub",
			"res://packages/006_voice_hub/scenes/voice_hub_panel.tscn",
			20,
			Color("#d6aa48")
		),
		_create_module(
			&"environment",
			"ENVIRONMENT",
			"ENV",
			&"009_environment_hub",
			"res://packages/009_environment_hub/scenes/environment_hub_panel.tscn",
			30,
			Color("#55f2a3")
		),
		_create_module(
			&"devices",
			"DEVICE HUB",
			"DEVICES",
			&"010_device_hub",
			"res://packages/010_device_hub/scenes/device_hub_panel.tscn",
			40,
			Color("#32d8ff")
		),
		_create_module(
			&"ai",
			"AI SYSTEM",
			"AI",
			&"011_ai_system",
			"res://packages/011_ai_system/scenes/ai_console_panel.tscn",
			50,
			Color("#d6aa48")
		),
		_create_module(
			&"automation",
			"AUTOMATION",
			"AUTO",
			&"012_automation",
			"res://packages/012_automation/scenes/automation_panel.tscn",
			60,
			Color("#55f2a3")
		),
		_create_module(
			&"diagnostics",
			"DIAGNOSTICS",
			"DIAG",
			&"013_diagnostics",
			"res://packages/013_diagnostics/scenes/diagnostics_panel.tscn",
			70,
			Color("#ffbf47")
		),
		_create_module(
			&"notifications",
			"NOTIFICATIONS",
			"NOTIFY",
			&"014_notification_center",
			"res://packages/014_notification_center/scenes/notification_center_panel.tscn",
			80,
			Color("#ff8b3d")
		),
	]

	for module in modules:
		if ResourceLoader.exists(module.scene_path):
			_service.register_module(module)


func _create_module(
	route_id: StringName,
	display_name: String,
	short_label: String,
	package_id: StringName,
	scene_path: String,
	sort_order: int,
	accent_color: Color
) -> HudModuleDefinition:
	var module := HudModuleDefinition.new()

	module.route_id = route_id
	module.display_name = display_name
	module.short_label = short_label
	module.package_id = package_id
	module.scene_path = scene_path
	module.sort_order = sort_order
	module.accent_color = accent_color
	module.enabled = true

	return module


func _apply_effect_configuration() -> void:
	_scanlines.visible = configuration.scanlines_enabled
	_vignette.visible = configuration.vignette_enabled
	_debug_overlay.visible = (
		configuration.debug_overlay_enabled
		and OS.is_debug_build()
	)

	var scanline_material := _scanlines.material as ShaderMaterial

	if scanline_material != null:
		scanline_material.set_shader_parameter(
			"opacity",
			configuration.scanline_opacity
		)

	var vignette_material := _vignette.material as ShaderMaterial

	if vignette_material != null:
		vignette_material.set_shader_parameter(
			"strength",
			configuration.vignette_strength
		)


func _bind_optional_services() -> void:
	var diagnostics := get_node_or_null("/root/Diagnostics")

	if diagnostics != null:
		diagnostics.health_state_changed.connect(
			_on_health_state_changed
		)

		_status_bar.set_health_state(
			diagnostics.get_health_state()
		)

	var notifications := get_node_or_null(
		"/root/NotificationCenter"
	)

	if notifications != null:
		notifications.notification_delivered.connect(
			_on_notification_delivered
		)


func _on_health_state_changed(
	_previous_state: SystemHealthState.Value,
	current_state: SystemHealthState.Value
) -> void:
	_status_bar.set_health_state(current_state)


func _on_notification_delivered(
	notification: HydraNotification
) -> void:
	var request := notification.get_request()

	_notification_output.text = (
		"[color=#d6aa48]%s[/color]\n"
		+ "[color=#32d8ff]%s[/color]"
	) % [
		request.get_title(),
		request.get_message(),
	]

	_notification_output.visible = true

	var tween := create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(
		_notification_output,
		"modulate:a",
		0.0,
		0.4
	)
	tween.tween_callback(
		func() -> void:
			_notification_output.visible = false
			_notification_output.modulate.a = 1.0
	)

#endregion