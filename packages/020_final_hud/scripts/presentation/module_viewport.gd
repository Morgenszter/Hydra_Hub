class_name ModuleViewport
extends Control
## Mounts active feature panels inside the Final HUD shell.


#region Signals

signal module_mounted(
	route_id: StringName,
	instance: Node
)
signal module_mount_failed(
	route_id: StringName,
	error: DomainError
)

#endregion


#region Nodes

@onready var _mount_point: Control = %MountPoint
@onready var _loading_label: RichTextLabel = %LoadingLabel
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: FinalHudService
var _active_instance: Node
var _active_route_id: StringName = &""

#endregion


#region Public API

## Binds this viewport to FinalHudService.
func bind_service(service: FinalHudService) -> void:
	assert(service != null, "Final HUD service cannot be null.")

	_disconnect_service()
	_service = service
	_service.route_changed.connect(
		_on_route_changed
	)


## Unmounts the current feature panel.
func clear_module() -> void:
	if _active_instance != null:
		_active_instance.queue_free()

	_active_instance = null
	_active_route_id = &""
	_loading_label.visible = true
	_error_label.visible = false

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.route_changed.is_connected(
		_on_route_changed
	):
		_service.route_changed.disconnect(
			_on_route_changed
		)


func _on_route_changed(
	module: HudModuleDefinition,
	_previous_route_id: StringName
) -> void:
	_mount_module(module)


func _mount_module(
	module: HudModuleDefinition
) -> void:
	clear_module()

	var resource := load(module.scene_path)

	if not resource is PackedScene:
		var error := DomainError.new(
			HydraErrors.INVALID_ARGUMENT,
			"HUD module resource is not a PackedScene.",
			{
				&"route_id": module.route_id,
				&"scene_path": module.scene_path,
			}
		)

		_show_error(module.route_id, error)
		return

	var scene := resource as PackedScene
	var instance := scene.instantiate()

	if instance == null:
		var instance_error := DomainError.new(
			HydraErrors.UNKNOWN,
			"HUD module scene could not be instantiated.",
			{&"route_id": module.route_id}
		)

		_show_error(module.route_id, instance_error)
		return

	_mount_point.add_child(instance)

	if instance is Control:
		var control := instance as Control
		control.position = Vector2.ZERO
		control.size = _mount_point.size
		control.set_anchors_preset(
			Control.PRESET_FULL_RECT
		)
		control.offset_left = 0.0
		control.offset_top = 0.0
		control.offset_right = 0.0
		control.offset_bottom = 0.0

	_active_instance = instance
	_active_route_id = module.route_id
	_loading_label.visible = false
	_error_label.visible = false

	module_mounted.emit(
		module.route_id,
		instance
	)


func _show_error(
	route_id: StringName,
	error: DomainError
) -> void:
	_loading_label.visible = false
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]MODULE MOUNT FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()

	module_mount_failed.emit(route_id, error)

#endregion