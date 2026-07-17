extends Control
class_name ToprailLayout

@export var auto_start_demo: bool = false
@export var demo_start_delay: float = 0.65
@export var terminal_path: NodePath = NodePath("Ramka_1_Central")

@export var hotkey_demo: Key = KEY_F6
@export var hotkey_connection_established: Key = KEY_F7
@export var hotkey_connection_lost: Key = KEY_F8
@export var hotkey_warning: Key = KEY_F9
@export var hotkey_error: Key = KEY_F10

@onready var _terminal: Node = get_node_or_null(terminal_path)

var _demo_running: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE

	if _terminal == null:
		push_warning("ToprailLayout: terminal node not found at path: %s" % str(terminal_path))

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


func report_connection_established(target: String = "HYDRA.GRID", arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_target := target

	if not arguments.is_empty():
		final_target = _join_arguments(arguments)

	_queue_terminal_log("NET", "CONNECTING TO %s" % final_target)
	_queue_terminal_log("OK", "SECURE LINK ESTABLISHED: %s" % final_target)
	_pulse_corner_link()
	_set_terminal_offline(false)


func report_connection_lost(target: String = "HYDRA.GRID", arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_target := target

	if not arguments.is_empty():
		final_target = _join_arguments(arguments)

	_queue_terminal_log("WARN", "SECURE LINK LOST: %s" % final_target)
	_pulse_corner_warning()
	_set_terminal_offline(true)


func report_system_error(message: String = "SYSTEM ERROR", arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_message := message

	if not arguments.is_empty():
		final_message = _join_arguments(arguments)

	_queue_terminal_log("ERR", final_message)
	_pulse_corner_error()
	_pulse_bottom_error()


func report_warning(message: String = "WARNING", arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_message := message

	if not arguments.is_empty():
		final_message = _join_arguments(arguments)

	_queue_terminal_log("WARN", final_message)
	_pulse_corner_warning()
	_pulse_bottom_warning()


func report_command(command: String = "STATUS", arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_command := command

	if not arguments.is_empty():
		final_command = _join_arguments(arguments)

	_queue_terminal_log("CMD", "> " + final_command)
	_pulse_bottom_submit()
	_pulse_corner_link()


func report_data(message: String = "DATA", arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_message := message

	if not arguments.is_empty():
		final_message = _join_arguments(arguments)

	_queue_terminal_log("DATA", final_message)


func report_power_level(label: String = "CORE", value: int = 100, arguments: PackedStringArray = PackedStringArray()) -> void:
	var final_label := label
	var final_value := clampi(value, 0, 100)

	if not arguments.is_empty():
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


func _queue_terminal_log(channel: String, message: String) -> void:
	if _terminal == null:
		push_warning("ToprailLayout: cannot queue log, terminal node is missing.")
		return

	if _terminal.has_method("queue_log"):
		_terminal.call("queue_log", channel, message)
	else:
		push_warning("ToprailLayout: terminal node does not expose queue_log(channel, message).")


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
	if has_method("pulse_all_corners_link"):
		call("pulse_all_corners_link")


func _pulse_corner_warning() -> void:
	if has_method("pulse_all_corners_warning"):
		call("pulse_all_corners_warning")


func _pulse_corner_error() -> void:
	if has_method("pulse_all_corners_error"):
		call("pulse_all_corners_error")


func _join_arguments(arguments: PackedStringArray) -> String:
	var result := ""

	for index in range(arguments.size()):
		if index > 0:
			result += " "

		result += arguments[index]

	return result


func _wait(seconds: float) -> void:
	if seconds <= 0.0:
		return

	await get_tree().create_timer(seconds).timeout
