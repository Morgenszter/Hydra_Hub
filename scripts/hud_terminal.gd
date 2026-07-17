class_name HudTerminal
extends Control


signal boot_finished
signal terminal_opened
signal terminal_cleared

signal log_printed(
	message: String,
	channel: String
)

signal command_submitted(
	raw_command: String,
	command_name: String,
	arguments: PackedStringArray
)


@onready var frame: Control = $Frame
@onready var boot_text: RichTextLabel = $BootText
@onready var terminal_log: RichTextLabel = $TerminalLog

@onready var command_prompt: Label = $CommandPrompt

@onready var command_input: TerminalCommandInput = (
	$CommandInput
)

@onready var terminal_fx: TerminalFX = $TerminalFX

@onready var bottom_line_fx: BottomLineFX = (
	$BottomLineFX
)

@onready var reveal_line: ColorRect = $RevealLine


@export_group("Startup")

@export var auto_start: bool = true
@export var add_default_startup_logs: bool = true


@export_group("Typing")

@export_range(0.001, 0.20, 0.001)
var character_delay: float = 0.022

@export_range(0.0, 2.0, 0.01)
var line_delay: float = 0.16

@export_range(0.0, 5.0, 0.05)
var ready_hold: float = 0.75


@export_group("Panel Reveal")

@export_range(0.05, 2.0, 0.01)
var reveal_duration: float = 0.45

@export_range(0.05, 1.0, 0.01)
var reveal_line_duration: float = 0.22

@export_range(0.01, 1.0, 0.01)
var reveal_line_fade_duration: float = 0.12

@export_range(0.01, 1.0, 0.01)
var terminal_fade_duration: float = 0.15

@export var reveal_color: Color = Color(
	0.30,
	1.00,
	0.80,
	1.00
)

@export var frame_pulse_color: Color = Color(
	0.45,
	1.00,
	0.75,
	1.00
)


@export_group("Terminal")

@export_range(10, 500, 1)
var max_log_lines: int = 80


@export_group("Command Line")

@export var command_prompt_text: String = ">"

@export_range(8, 72, 1)
var command_prompt_font_size: int = 18

@export var command_prompt_color: Color = Color(
	0.60,
	1.00,
	0.82,
	1.00
)


const BOOT_LINES: Array[String] = [
	"> BOOTING HYDRA CORE...",
	"> INITIALIZING TACTICAL INTERFACE...",
	"> CONNECTING SECURE CHANNEL...",
	"> VERIFYING CIPHER KEYS...",
	"> SYNCHRONIZING DATA NODES...",
	"> LOADING COMBAT TELEMETRY...",
	"> READY"
]


var _log_queue: Array[Dictionary] = []

var _sequence_running: bool = false
var _terminal_ready: bool = false
var _processing_queue: bool = false
var _fx_enabled_requested: bool = true

var _typing_revision: int = 0
var _queue_worker_revision: int = 0


func _ready() -> void:
	_configure_nodes()
	_connect_signals()
	_reset_visual_state()

	if auto_start:
		call_deferred(
			"start_sequence"
		)


# -------------------------------------------------------------------
# PUBLIC API
# -------------------------------------------------------------------

func start_sequence() -> void:
	if _sequence_running:
		return

	_sequence_running = true
	_terminal_ready = false

	_reset_visual_state()

	await get_tree().process_frame

	await _play_panel_reveal()

	terminal_fx.set_fx_enabled(
		_fx_enabled_requested
	)

	if _fx_enabled_requested:
		await terminal_fx.pulse_glitch(
			0.016,
			0.09
		)

	boot_text.show()

	await _run_boot_sequence()
	await _wait(ready_hold)

	boot_finished.emit()

	await _open_terminal()

	if add_default_startup_logs:
		_enqueue_log(
			"SESSION ESTABLISHED",
			"OK"
		)

		_enqueue_log(
			"SECURE CHANNEL ACTIVE",
			"NET"
		)

		_enqueue_log(
			"COMMAND INTERFACE ONLINE",
			"SYS"
		)

		_enqueue_log(
			"TYPE HELP FOR AVAILABLE COMMANDS",
			"DATA"
		)

	_terminal_ready = true
	_sequence_running = false

	_enable_command_line()

	terminal_opened.emit()

	_try_start_queue_processing()


func restart_sequence(
	clear_pending_logs: bool = true
) -> void:
	if _sequence_running:
		return

	_terminal_ready = false

	_cancel_queue_worker()
	_cancel_typing()
	_disable_command_line()

	if clear_pending_logs:
		_log_queue.clear()

	await start_sequence()


func push_log(
	message: String,
	channel: String = "SYS"
) -> void:
	var cleaned_message: String = (
		message.strip_edges()
	)

	if cleaned_message.is_empty():
		return

	var normalized_channel: String = (
		channel
		.strip_edges()
		.to_upper()
	)

	if normalized_channel.is_empty():
		normalized_channel = "SYS"

	_enqueue_log(
		cleaned_message,
		normalized_channel
	)

	_try_start_queue_processing()


func push_ok(message: String) -> void:
	push_log(
		message,
		"OK"
	)


func push_network(message: String) -> void:
	push_log(
		message,
		"NET"
	)


func push_warning(message: String) -> void:
	push_log(
		message,
		"WARN"
	)


func push_error_log(message: String) -> void:
	push_log(
		message,
		"ERR"
	)


func push_command(message: String) -> void:
	push_log(
		message,
		"CMD"
	)


func push_data(message: String) -> void:
	push_log(
		message,
		"DATA"
	)


func clear_terminal(
	clear_pending_logs: bool = true
) -> void:
	_cancel_queue_worker()
	_cancel_typing()

	if clear_pending_logs:
		_log_queue.clear()

	terminal_log.clear()
	terminal_log.visible_characters = 0

	terminal_cleared.emit()

	if (
		_terminal_ready
		and not _log_queue.is_empty()
	):
		_try_start_queue_processing()


func clear_command_history() -> void:
	command_input.clear_history()


func focus_command_input() -> void:
	if not _terminal_ready:
		return

	command_input.request_terminal_focus()


func set_command_input_enabled(
	value: bool
) -> void:
	if value and not _terminal_ready:
		return

	command_prompt.visible = value
	command_input.visible = value

	command_input.set_input_enabled(
		value
	)

	bottom_line_fx.set_input_active(
		value
	)

	bottom_line_fx.set_fx_enabled(
		value
		and _fx_enabled_requested
	)


func set_terminal_fx_enabled(
	value: bool
) -> void:
	_fx_enabled_requested = value

	terminal_fx.set_fx_enabled(
		value
		and (
			_sequence_running
			or _terminal_ready
		)
	)

	bottom_line_fx.set_fx_enabled(
		value
		and _terminal_ready
		and command_input.visible
	)


func is_terminal_fx_enabled() -> bool:
	return _fx_enabled_requested


func pulse_terminal_glitch(
	strength: float = -1.0,
	duration: float = -1.0
) -> void:
	if not _fx_enabled_requested:
		return

	await terminal_fx.pulse_glitch(
		strength,
		duration
	)


func pulse_bottom_line() -> void:
	if not _fx_enabled_requested:
		return

	bottom_line_fx.pulse_submit()


func is_terminal_ready() -> bool:
	return _terminal_ready


func is_sequence_running() -> bool:
	return _sequence_running


func get_pending_log_count() -> int:
	return _log_queue.size()


# -------------------------------------------------------------------
# SIGNALS
# -------------------------------------------------------------------

func _connect_signals() -> void:
	if not command_input.command_entered.is_connected(
		_on_command_entered
	):
		command_input.command_entered.connect(
			_on_command_entered
		)


func _on_command_entered(
	raw_command: String
) -> void:
	if not _terminal_ready:
		return

	bottom_line_fx.pulse_submit()

	var parsed_command: Dictionary = (
		_parse_command(raw_command)
	)

	var command_name: String = str(
		parsed_command.get(
			"command",
			""
		)
	)

	var arguments: PackedStringArray = (
		parsed_command.get(
			"arguments",
			PackedStringArray()
		)
	)

	push_command(raw_command)

	command_submitted.emit(
		raw_command,
		command_name,
		arguments
	)


# -------------------------------------------------------------------
# COMMAND PARSER
# -------------------------------------------------------------------

func _parse_command(
	raw_command: String
) -> Dictionary:
	var tokens: PackedStringArray = (
		_tokenize_command(raw_command)
	)

	if tokens.is_empty():
		return {
			"command": "",
			"arguments": PackedStringArray()
		}

	var command_name: String = (
		tokens[0].to_upper()
	)

	var arguments: PackedStringArray = (
		PackedStringArray()
	)

	for index: int in range(
		1,
		tokens.size()
	):
		arguments.append(
			tokens[index]
		)

	return {
		"command": command_name,
		"arguments": arguments
	}


func _tokenize_command(
	raw_command: String
) -> PackedStringArray:
	var tokens: PackedStringArray = (
		PackedStringArray()
	)

	var current_token: String = ""
	var quote_character: String = ""

	var inside_quotes: bool = false
	var escaping: bool = false

	for index: int in range(
		raw_command.length()
	):
		var character: String = (
			raw_command.substr(
				index,
				1
			)
		)

		if escaping:
			current_token += character
			escaping = false
			continue

		if character == "\\":
			escaping = true
			continue

		if inside_quotes:
			if character == quote_character:
				inside_quotes = false
				quote_character = ""
			else:
				current_token += character

			continue

		if (
			character == "\""
			or character == "'"
		):
			inside_quotes = true
			quote_character = character
			continue

		if (
			character == " "
			or character == "\t"
		):
			if not current_token.is_empty():
				tokens.append(
					current_token
				)

				current_token = ""

			continue

		current_token += character

	if escaping:
		current_token += "\\"

	if not current_token.is_empty():
		tokens.append(
			current_token
		)

	return tokens


# -------------------------------------------------------------------
# NODE CONFIGURATION
# -------------------------------------------------------------------

func _configure_nodes() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	frame.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	reveal_line.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	reveal_line.focus_mode = (
		Control.FOCUS_NONE
	)

	_configure_boot_text()
	_configure_terminal_log()
	_configure_command_prompt()


func _configure_boot_text() -> void:
	boot_text.fit_content = false
	boot_text.scroll_active = false
	boot_text.scroll_following = false

	boot_text.scroll_following_visible_characters = (
		false
	)

	boot_text.bbcode_enabled = false
	boot_text.threaded = false

	boot_text.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	boot_text.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	boot_text.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	boot_text.focus_mode = (
		Control.FOCUS_NONE
	)

	boot_text.selection_enabled = false
	boot_text.context_menu_enabled = false
	boot_text.shortcut_keys_enabled = false
	boot_text.clip_contents = true


func _configure_terminal_log() -> void:
	terminal_log.fit_content = false
	terminal_log.scroll_active = true
	terminal_log.scroll_following = true

	terminal_log.scroll_following_visible_characters = (
		true
	)

	terminal_log.bbcode_enabled = false
	terminal_log.threaded = false

	terminal_log.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_LEFT
	)

	terminal_log.vertical_alignment = (
		VERTICAL_ALIGNMENT_TOP
	)

	terminal_log.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	terminal_log.focus_mode = (
		Control.FOCUS_NONE
	)

	terminal_log.selection_enabled = false
	terminal_log.context_menu_enabled = false
	terminal_log.shortcut_keys_enabled = false
	terminal_log.clip_contents = true


func _configure_command_prompt() -> void:
	command_prompt.text = command_prompt_text

	command_prompt.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	command_prompt.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)

	command_prompt.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	command_prompt.focus_mode = (
		Control.FOCUS_NONE
	)

	command_prompt.add_theme_font_size_override(
		&"font_size",
		command_prompt_font_size
	)

	command_prompt.add_theme_color_override(
		&"font_color",
		command_prompt_color
	)


func _reset_visual_state() -> void:
	_cancel_queue_worker()
	_cancel_typing()
	_disable_command_line()

	scale = Vector2.ONE
	modulate = Color.WHITE

	frame.self_modulate = Color.WHITE

	reveal_line.hide()
	reveal_line.scale = Vector2.ONE
	reveal_line.modulate = reveal_color

	boot_text.clear()
	boot_text.visible_characters = 0
	boot_text.modulate = Color.WHITE
	boot_text.hide()

	terminal_log.clear()
	terminal_log.visible_characters = 0
	terminal_log.modulate = Color.WHITE
	terminal_log.hide()

	terminal_fx.set_fx_enabled(false)

	bottom_line_fx.set_input_active(false)
	bottom_line_fx.set_fx_enabled(false)
	bottom_line_fx.reset_effects()


# -------------------------------------------------------------------
# COMMAND LINE
# -------------------------------------------------------------------

func _enable_command_line() -> void:
	command_prompt.show()
	command_input.show()

	command_input.clear_input()
	command_input.set_input_enabled(true)

	bottom_line_fx.set_fx_enabled(
		_fx_enabled_requested
	)

	bottom_line_fx.set_input_active(true)


func _disable_command_line() -> void:
	command_input.set_input_enabled(false)
	command_input.clear_input()
	command_input.hide()

	command_prompt.hide()

	if is_instance_valid(bottom_line_fx):
		bottom_line_fx.set_input_active(false)
		bottom_line_fx.set_fx_enabled(false)


# -------------------------------------------------------------------
# PANEL REVEAL
# -------------------------------------------------------------------

func _play_panel_reveal() -> void:
	pivot_offset = size * 0.5

	scale = Vector2(
		1.0,
		0.015
	)

	modulate = Color(
		reveal_color.r,
		reveal_color.g,
		reveal_color.b,
		0.0
	)

	reveal_line.show()

	reveal_line.pivot_offset = (
		reveal_line.size * 0.5
	)

	reveal_line.scale = Vector2(
		0.0,
		1.0
	)

	reveal_line.modulate = reveal_color

	var reveal_tween: Tween = create_tween()

	reveal_tween.set_parallel(true)

	reveal_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		reveal_duration
	).set_trans(
		Tween.TRANS_EXPO
	).set_ease(
		Tween.EASE_OUT
	)

	reveal_tween.tween_property(
		self,
		"modulate",
		Color.WHITE,
		minf(
			reveal_duration,
			0.18
		)
	).set_trans(
		Tween.TRANS_LINEAR
	)

	reveal_tween.tween_property(
		reveal_line,
		"scale",
		Vector2.ONE,
		reveal_line_duration
	).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(
		Tween.EASE_OUT
	)

	await reveal_tween.finished

	scale = Vector2.ONE
	modulate = Color.WHITE

	var line_fade_tween: Tween = create_tween()

	line_fade_tween.tween_property(
		reveal_line,
		"modulate:a",
		0.0,
		reveal_line_fade_duration
	)

	await line_fade_tween.finished

	reveal_line.hide()
	reveal_line.scale = Vector2.ONE
	reveal_line.modulate = reveal_color

	await _frame_power_pulse()


func _frame_power_pulse() -> void:
	var pulse_tween: Tween = create_tween()

	pulse_tween.tween_property(
		frame,
		"self_modulate",
		frame_pulse_color,
		0.06
	)

	pulse_tween.tween_property(
		frame,
		"self_modulate",
		Color.WHITE,
		0.16
	)

	await pulse_tween.finished

	frame.self_modulate = Color.WHITE


# -------------------------------------------------------------------
# BOOT
# -------------------------------------------------------------------

func _run_boot_sequence() -> void:
	for line: String in BOOT_LINES:
		var completed: bool = await _append_boot_line(
			line
		)

		if not completed:
			return

		await _wait(line_delay)


func _append_boot_line(
	line: String
) -> bool:
	if boot_text.get_total_character_count() > 0:
		boot_text.newline()

	var start_character: int = (
		boot_text.get_total_character_count()
	)

	boot_text.add_text(line)

	var target_character: int = (
		boot_text.get_total_character_count()
	)

	var typing_revision: int = (
		_typing_revision
	)

	return await _animate_visible_characters(
		boot_text,
		start_character,
		target_character,
		typing_revision
	)


# -------------------------------------------------------------------
# TERMINAL OPENING
# -------------------------------------------------------------------

func _open_terminal() -> void:
	boot_text.hide()

	terminal_log.clear()
	terminal_log.visible_characters = 0

	terminal_log.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.0
	)

	terminal_log.show()

	var fade_tween: Tween = create_tween()

	fade_tween.tween_property(
		terminal_log,
		"modulate:a",
		1.0,
		terminal_fade_duration
	)

	await fade_tween.finished

	terminal_log.modulate = Color.WHITE


# -------------------------------------------------------------------
# LOG QUEUE
# -------------------------------------------------------------------

func _enqueue_log(
	message: String,
	channel: String
) -> void:
	_log_queue.push_back({
		"message": message,
		"channel": channel
	})


func _try_start_queue_processing() -> void:
	if not _terminal_ready:
		return

	if _processing_queue:
		return

	if _log_queue.is_empty():
		return

	_processing_queue = true
	_queue_worker_revision += 1

	var worker_revision: int = (
		_queue_worker_revision
	)

	call_deferred(
		"_process_log_queue",
		worker_revision
	)


func _process_log_queue(
	worker_revision: int
) -> void:
	while (
		worker_revision == _queue_worker_revision
		and _terminal_ready
		and not _log_queue.is_empty()
	):
		var entry: Dictionary = (
			_log_queue.pop_front()
		)

		var message: String = str(
			entry.get(
				"message",
				""
			)
		)

		var channel: String = str(
			entry.get(
				"channel",
				"SYS"
			)
		)

		_play_channel_fx(channel)

		var completed: bool = await _append_terminal_line(
			message,
			channel
		)

		if worker_revision != _queue_worker_revision:
			return

		if not completed:
			return

		log_printed.emit(
			message,
			channel
		)

		await _wait(line_delay)

	if worker_revision != _queue_worker_revision:
		return

	_processing_queue = false

	if (
		_terminal_ready
		and not _log_queue.is_empty()
	):
		_try_start_queue_processing()


func _append_terminal_line(
	message: String,
	channel: String
) -> bool:
	_trim_old_terminal_lines()

	if terminal_log.get_total_character_count() > 0:
		terminal_log.newline()

	var start_character: int = (
		terminal_log.get_total_character_count()
	)

	terminal_log.push_color(
		_get_channel_color(channel)
	)

	terminal_log.add_text(
		"[%s]" % channel
	)

	terminal_log.pop()

	terminal_log.add_text(
		" " + message
	)

	var target_character: int = (
		terminal_log.get_total_character_count()
	)

	var typing_revision: int = (
		_typing_revision
	)

	return await _animate_visible_characters(
		terminal_log,
		start_character,
		target_character,
		typing_revision
	)


func _trim_old_terminal_lines() -> void:
	if max_log_lines <= 0:
		return

	while (
		terminal_log.get_total_character_count() > 0
		and terminal_log.get_paragraph_count() >= max_log_lines
	):
		var removed: bool = (
			terminal_log.remove_paragraph(0)
		)

		if not removed:
			break

	terminal_log.visible_characters = -1


func _play_channel_fx(
	channel: String
) -> void:
	match channel:
		"ERR":
			if _fx_enabled_requested:
				terminal_fx.pulse_error_glitch()
				bottom_line_fx.pulse_error()

		"WARN":
			if _fx_enabled_requested:
				terminal_fx.pulse_warning_glitch()
				bottom_line_fx.pulse_warning()


# -------------------------------------------------------------------
# TYPEWRITER
# -------------------------------------------------------------------

func _animate_visible_characters(
	label: RichTextLabel,
	start_character: int,
	target_character: int,
	typing_revision: int
) -> bool:
	label.visible_characters = start_character

	if target_character <= start_character:
		label.visible_characters = target_character
		return true

	if character_delay <= 0.0:
		label.visible_characters = target_character
		return true

	while label.visible_characters < target_character:
		if typing_revision != _typing_revision:
			return false

		label.visible_characters += 1

		await _wait(character_delay)

	if typing_revision != _typing_revision:
		return false

	label.visible_characters = target_character

	return true


func _cancel_typing() -> void:
	_typing_revision += 1


func _cancel_queue_worker() -> void:
	_queue_worker_revision += 1
	_processing_queue = false


# -------------------------------------------------------------------
# COLORS
# -------------------------------------------------------------------

func _get_channel_color(
	channel: String
) -> Color:
	match channel:
		"OK":
			return Color(
				0.35,
				1.00,
				0.65,
				1.00
			)

		"NET":
			return Color(
				0.30,
				0.85,
				1.00,
				1.00
			)

		"DATA":
			return Color(
				0.70,
				0.65,
				1.00,
				1.00
			)

		"WARN":
			return Color(
				1.00,
				0.72,
				0.25,
				1.00
			)

		"ERR":
			return Color(
				1.00,
				0.28,
				0.32,
				1.00
			)

		"CMD":
			return Color(
				0.95,
				0.95,
				0.95,
				1.00
			)

		_:
			return Color(
				0.60,
				1.00,
				0.82,
				1.00
			)


# -------------------------------------------------------------------
# UTILS
# -------------------------------------------------------------------

func _wait(duration: float) -> void:
	if duration <= 0.0:
		return

	await get_tree().create_timer(
		duration
	).timeout
