extends Control
class_name HudController

const COMMAND_OK := 0
const COMMAND_WARNING := 1
const COMMAND_ERROR := 2

const CORNER_SLOT_LEFT_BOTTOM := 0
const CORNER_SLOT_RIGHT_TOP := 1
const CORNER_SLOT_LEFT_TOP := 2

const CORNER_FX_Z_INDEX := 3

@export var auto_start_boot: bool = true
@export var configure_nodes_on_ready: bool = true

@export var left_bottom_activation_delay: float = 0.10
@export var right_top_activation_delay: float = 0.22
@export var left_top_activation_delay: float = 0.34

@export_group("Debug / Demo Hotkeys")
@export var auto_start_demo: bool = false
@export var demo_start_delay: float = 0.65
@export var hotkey_demo: int = KEY_F6
@export var hotkey_connection_established: int = KEY_F7
@export var hotkey_connection_lost: int = KEY_F8
@export var hotkey_warning: int = KEY_F9
@export var hotkey_error: int = KEY_F10

var _background: Control = null

var _terminal: Node = null

var _left_bottom_panel: Control = null
var _right_top_panel: Control = null
var _left_top_panel: Control = null

var _left_bottom_frame: CanvasItem = null
var _right_top_frame: CanvasItem = null
var _left_top_frame: CanvasItem = null

var _left_bottom_fx: Node = null
var _right_top_fx: Node = null
var _left_top_fx: Node = null

var _corner_fxs: Array[Node] = []
var _hud_fx_enabled: bool = true
var _demo_running: bool = false


func _ready() -> void:
	_resolve_scene_nodes()

	if configure_nodes_on_ready:
		_configure_hud_node()
		_configure_background()
		_configure_side_panels()
		_configure_corner_fx_nodes()

	_collect_corner_fxs()
	_connect_terminal_signals()
	_shutdown_all_corner_fxs()

	if auto_start_boot:
		call_deferred("_start_terminal_boot")

	if auto_start_demo:
		call_deferred("_run_terminal_demo")


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey

	if key_event == null:
		return

	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		hotkey_demo:
			_run_terminal_demo()
			get_viewport().set_input_as_handled()

		hotkey_connection_established:
			report_connection_established("HYDRA.GRID")
			get_viewport().set_input_as_handled()

		hotkey_connection_lost:
			report_connection_lost("HYDRA.GRID")
			get_viewport().set_input_as_handled()

		hotkey_warning:
			report_warning("AUSPEX NOISE ABOVE BASELINE")
			get_viewport().set_input_as_handled()

		hotkey_error:
			report_system_error("SIMULATED SYSTEM FAULT")
			get_viewport().set_input_as_handled()


func set_hud_fx_enabled(value: bool) -> void:
	_hud_fx_enabled = value

	if not value:
		_shutdown_all_corner_fxs()
	else:
		_activate_corner_fxs_after_boot()


func pulse_all_corners_link() -> void:
	for fx in _corner_fxs:
		_call_if_method_exists(fx, &"pulse_link")


func pulse_all_corners_warning() -> void:
	for fx in _corner_fxs:
		_call_if_method_exists(fx, &"pulse_warning")


func pulse_all_corners_error() -> void:
	for fx in _corner_fxs:
		_call_if_method_exists(fx, &"pulse_error")


func set_all_corners_offline(value: bool) -> void:
	for fx in _corner_fxs:
		_call_if_method_exists(fx, &"set_offline", [value])


func report_connection_established(target: String = "HYDRA.GRID", arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_target := target

	if arguments.size() > 0:
		final_target = _join_arguments(arguments)

	_queue_terminal_log("NET", "CONNECTING TO %s" % final_target)
	_queue_terminal_log("OK", "SECURE LINK ESTABLISHED: %s" % final_target)
	_pulse_corner_link()
	_set_terminal_offline(false)


func report_connection_lost(target: String = "HYDRA.GRID", arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_target := target

	if arguments.size() > 0:
		final_target = _join_arguments(arguments)

	_queue_terminal_log("WARN", "SECURE LINK LOST: %s" % final_target)
	_pulse_corner_warning()
	_set_terminal_offline(true)


func report_system_error(message: String = "SYSTEM ERROR", arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_message := message

	if arguments.size() > 0:
		final_message = _join_arguments(arguments)

	_queue_terminal_log("ERR", final_message)
	_pulse_corner_error()
	_pulse_bottom_error()


func report_warning(message: String = "WARNING", arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_message := message

	if arguments.size() > 0:
		final_message = _join_arguments(arguments)

	_queue_terminal_log("WARN", final_message)
	_pulse_corner_warning()
	_pulse_bottom_warning()


func report_command(command: String = "STATUS", arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_command := command

	if arguments.size() > 0:
		final_command = _join_arguments(arguments)

	_queue_terminal_log("CMD", "> " + final_command)
	_pulse_bottom_submit()
	_pulse_corner_link()


func report_data(message: String = "DATA", arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_message := message

	if arguments.size() > 0:
		final_message = _join_arguments(arguments)

	_queue_terminal_log("DATA", final_message)


func report_power_level(label: String = "CORE", value: int = 100, arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_label := label
	var final_value := clampi(value, 0, 100)

	if arguments.size() > 0:
		final_label = _join_arguments(arguments)

	var channel := "OK"

	if final_value <= 20:
		channel = "ERR"
	elif final_value <= 45:
		channel = "WARN"
	else:
		channel = "SYS"

	_queue_terminal_log(channel, "POWER %s: %d%%" % [final_label.to_upper(), final_value])

	if final_value <= 20:
		_pulse_corner_error()
		_pulse_bottom_error()
	elif final_value <= 45:
		_pulse_corner_warning()
		_pulse_bottom_warning()
	else:
		_pulse_corner_link()


func _resolve_scene_nodes() -> void:
	_background = _find_node_by_name("Background") as Control

	_terminal = _find_node_by_name("Ramka_1_Central")

	_left_bottom_panel = _find_node_by_name("Ramka_2_LeftCornerBottom") as Control
	_right_top_panel = _find_node_by_name("Ramka_3_RightTop") as Control
	_left_top_panel = _find_node_by_name("Ramka_6_LeftTopCorner") as Control

	_left_bottom_frame = _find_child_canvas_item(_left_bottom_panel, "Frame")
	_right_top_frame = _find_child_canvas_item(_right_top_panel, "Frame")
	_left_top_frame = _find_child_canvas_item(_left_top_panel, "Frame")

	_left_bottom_fx = _find_child_node(_left_bottom_panel, "CornerFrameFX")
	_right_top_fx = _find_child_node(_right_top_panel, "CornerFrameFX")
	_left_top_fx = _find_child_node(_left_top_panel, "CornerFrameFX")


func _configure_hud_node() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE

	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0


func _configure_background() -> void:
	if _background == null:
		return

	_background.z_index = -10
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.focus_mode = Control.FOCUS_NONE


func _configure_side_panels() -> void:
	_configure_side_panel(_left_bottom_panel, _left_bottom_frame)
	_configure_side_panel(_right_top_panel, _right_top_frame)
	_configure_side_panel(_left_top_panel, _left_top_frame)


func _configure_side_panel(panel: Control, frame: CanvasItem) -> void:
	if panel != null:
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.focus_mode = Control.FOCUS_NONE

	if frame != null:
		frame.z_index = 0

		if frame is Control:
			var frame_control := frame as Control
			frame_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame_control.focus_mode = Control.FOCUS_NONE


func _configure_corner_fx_nodes() -> void:
	_configure_corner_fx_node(
		_left_bottom_fx,
		CORNER_SLOT_LEFT_BOTTOM,
		"Ramka_2_LeftCornerBottom/CornerFrameFX"
	)

	_configure_corner_fx_node(
		_right_top_fx,
		CORNER_SLOT_RIGHT_TOP,
		"Ramka_3_RightTop/CornerFrameFX"
	)

	_configure_corner_fx_node(
		_left_top_fx,
		CORNER_SLOT_LEFT_TOP,
		"Ramka_6_LeftTopCorner/CornerFrameFX"
	)


func _configure_corner_fx_node(fx: Node, slot: int, path_label: String) -> void:
	if fx == null:
		push_warning("HudController: missing node %s. Check exact node name and hierarchy." % path_label)
		return

	if fx is Control:
		var fx_control := fx as Control

		fx_control.z_index = CORNER_FX_Z_INDEX
		fx_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx_control.focus_mode = Control.FOCUS_NONE

		fx_control.anchor_left = 0.0
		fx_control.anchor_top = 0.0
		fx_control.anchor_right = 1.0
		fx_control.anchor_bottom = 1.0

		fx_control.offset_left = 0.0
		fx_control.offset_top = 0.0
		fx_control.offset_right = 0.0
		fx_control.offset_bottom = 0.0

	if fx.has_method("configure_as_overlay"):
		fx.call("configure_as_overlay", slot)
	else:
		push_warning("HudController: node %s exists, but it does not have corner_frame_fx.gd attached." % path_label)


func _collect_corner_fxs() -> void:
	_corner_fxs.clear()

	if _left_bottom_fx != null:
		_corner_fxs.append(_left_bottom_fx)

	if _right_top_fx != null:
		_corner_fxs.append(_right_top_fx)

	if _left_top_fx != null:
		_corner_fxs.append(_left_top_fx)


func _connect_terminal_signals() -> void:
	if _terminal == null:
		push_warning("HudController: missing node Ramka_1_Central. Controller will run without terminal binding.")
		return

	_connect_terminal_signal(&"boot_started", &"_on_terminal_boot_started")
	_connect_terminal_signal(&"boot_finished", &"_on_terminal_boot_finished")
	_connect_terminal_signal(&"command_submitted", &"_on_terminal_command_submitted")
	_connect_terminal_signal(&"command_processed", &"_on_terminal_command_processed")
	_connect_terminal_signal(&"link_state_changed", &"_on_terminal_link_state_changed")
	_connect_terminal_signal(&"terminal_fx_state_changed", &"_on_terminal_fx_state_changed")
	_connect_terminal_signal(&"reboot_started", &"_on_terminal_reboot_started")
	_connect_terminal_signal(&"reboot_finished", &"_on_terminal_reboot_finished")


func _connect_terminal_signal(signal_name: StringName, method_name: StringName) -> void:
	if _terminal == null:
		return

	if not _terminal.has_signal(signal_name):
		return

	var callable := Callable(self, method_name)

	if not _terminal.is_connected(signal_name, callable):
		_terminal.connect(signal_name, callable)


func _start_terminal_boot() -> void:
	if _terminal == null:
		return

	if _terminal.has_method("is_boot_running"):
		var boot_running := bool(_terminal.call("is_boot_running"))

		if boot_running:
			return

	if _terminal.has_method("start_boot_sequence"):
		_terminal.call("start_boot_sequence")


func _shutdown_all_corner_fxs() -> void:
	for fx in _corner_fxs:
		_call_if_method_exists(fx, &"shutdown")


func _activate_corner_fxs_after_boot() -> void:
	if not _hud_fx_enabled:
		return

	if _left_bottom_fx != null and _left_bottom_fx.has_method("activate_delayed"):
		_left_bottom_fx.call("activate_delayed", left_bottom_activation_delay, true)

	if _right_top_fx != null and _right_top_fx.has_method("activate_delayed"):
		_right_top_fx.call("activate_delayed", right_top_activation_delay, true)

	if _left_top_fx != null and _left_top_fx.has_method("activate_delayed"):
		_left_top_fx.call("activate_delayed", left_top_activation_delay, true)


func _run_terminal_demo() -> void:
	if _demo_running:
		return

	_demo_running = true

	if demo_start_delay > 0.0:
		await _wait(demo_start_delay)

	report_data("TOPRAIL DIAGNOSTIC SEQUENCE INITIALIZED")
	await _wait(0.20)

	report_power_level("CORE", 97)
	await _wait(0.20)

	report_connection_established("HYDRA.GRID")
	await _wait(0.20)

	report_data("TACTICAL BUFFER: 17 PACKETS")
	await _wait(0.20)

	report_warning("AUSPEX NOISE ABOVE BASELINE")
	await _wait(0.20)

	report_command("STATUS")
	await _wait(0.20)

	report_data("PANEL=ONLINE LINK=ONLINE INPUT=ACTIVE")
	await _wait(0.20)

	report_connection_lost("OMEGA.RELAY")
	await _wait(0.20)

	report_system_error("OMEGA.RELAY HANDSHAKE FAILED")
	await _wait(0.20)

	report_connection_established("HYDRA.GRID")
	await _wait(0.20)

	report_data("TOPRAIL DIAGNOSTIC SEQUENCE COMPLETE")

	_demo_running = false


func _queue_terminal_log(channel: String, message: String) -> void:
	if _terminal == null:
		push_warning("HudController: cannot queue log, terminal node is missing.")
		return

	if _terminal.has_method("queue_log"):
		_terminal.call("queue_log", channel, message)
	else:
		push_warning("HudController: terminal node does not expose queue_log(channel, message).")


func _set_terminal_offline(value: bool) -> void:
	if _terminal == null:
		return

	if _terminal.has_method("set_terminal_offline"):
		_terminal.call("set_terminal_offline", value)


func _pulse_bottom_submit() -> void:
	if _terminal == null:
		return

	if _terminal.has_method("pulse_bottom_submit"):
		_terminal.call("pulse_bottom_submit")


func _pulse_bottom_warning() -> void:
	if _terminal == null:
		return

	if _terminal.has_method("pulse_bottom_warning"):
		_terminal.call("pulse_bottom_warning")


func _pulse_bottom_error() -> void:
	if _terminal == null:
		return

	if _terminal.has_method("pulse_bottom_error"):
		_terminal.call("pulse_bottom_error")


func _pulse_corner_link() -> void:
	pulse_all_corners_link()


func _pulse_corner_warning() -> void:
	pulse_all_corners_warning()


func _pulse_corner_error() -> void:
	pulse_all_corners_error()


func _on_terminal_boot_started() -> void:
	_shutdown_all_corner_fxs()


func _on_terminal_boot_finished() -> void:
	_activate_corner_fxs_after_boot()


func _on_terminal_command_submitted(_command: String) -> void:
	if not _hud_fx_enabled:
		return

	if _left_bottom_fx != null and _left_bottom_fx.has_method("pulse_link"):
		_left_bottom_fx.call("pulse_link")


func _on_terminal_command_processed(_command: String, status: int) -> void:
	if not _hud_fx_enabled:
		return

	match status:
		COMMAND_OK:
			if _right_top_fx != null and _right_top_fx.has_method("pulse_link"):
				_right_top_fx.call("pulse_link")

			if _left_top_fx != null and _left_top_fx.has_method("pulse_link"):
				_left_top_fx.call("pulse_link")

		COMMAND_WARNING:
			pulse_all_corners_warning()

		COMMAND_ERROR:
			pulse_all_corners_error()


func _on_terminal_link_state_changed(is_offline: bool) -> void:
	set_all_corners_offline(is_offline)

	if not _hud_fx_enabled:
		return

	if is_offline:
		pulse_all_corners_warning()
	else:
		pulse_all_corners_link()


func _on_terminal_fx_state_changed(terminal_fx_enabled: bool, bottom_line_fx_enabled: bool) -> void:
	var any_terminal_fx_enabled := terminal_fx_enabled or bottom_line_fx_enabled

	if not any_terminal_fx_enabled:
		_shutdown_all_corner_fxs()
		return

	if not _hud_fx_enabled:
		return

	if _terminal != null and _terminal.has_method("is_terminal_ready"):
		var terminal_ready := bool(_terminal.call("is_terminal_ready"))

		if terminal_ready:
			_activate_corner_fxs_after_boot()


func _on_terminal_reboot_started() -> void:
	_shutdown_all_corner_fxs()


func _on_terminal_reboot_finished() -> void:
	if not _hud_fx_enabled:
		return

	_activate_corner_fxs_after_boot()
	pulse_all_corners_link()


func _find_node_by_name(node_name: String) -> Node:
	var direct := get_node_or_null(NodePath(node_name))

	if direct != null:
		return direct

	var recursive := find_child(node_name, true, false)

	if recursive != null:
		return recursive

	var current_scene := get_tree().current_scene

	if current_scene != null and current_scene != self:
		var scene_direct := current_scene.get_node_or_null(NodePath(node_name))

		if scene_direct != null:
			return scene_direct

		var scene_recursive := current_scene.find_child(node_name, true, false)

		if scene_recursive != null:
			return scene_recursive

	return null


func _find_child_node(parent_node: Node, child_name: String) -> Node:
	if parent_node == null:
		return null

	var direct := parent_node.get_node_or_null(NodePath(child_name))

	if direct != null:
		return direct

	return parent_node.find_child(child_name, true, false)


func _find_child_canvas_item(parent_node: Node, child_name: String) -> CanvasItem:
	var child := _find_child_node(parent_node, child_name)

	if child is CanvasItem:
		return child as CanvasItem

	return null


func _join_arguments(arguments: PackedStringArray) -> String:
	var result := ""

	for index in range(arguments.size()):
		if index > 0:
			result += " "

		result += arguments[index]

	return result


func _call_if_method_exists(target_node: Node, method_name: StringName, arguments: Array = []) -> void:
	if target_node == null:
		return

	if not target_node.has_method(method_name):
		return

	target_node.callv(method_name, arguments)


func _wait(seconds: float) -> void:
	if seconds <= 0.0:
		return

	await get_tree().create_timer(seconds).timeout
