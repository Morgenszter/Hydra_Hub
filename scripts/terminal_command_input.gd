class_name TerminalCommandInput
extends LineEdit


signal command_entered(command: String)


@export_group("Input")

@export var terminal_placeholder: String = "ENTER COMMAND"

@export_range(1, 512, 1)
var command_max_length: int = 128

@export_range(1, 256, 1)
var max_history_entries: int = 32

@export var focus_when_enabled: bool = true


@export_group("Caret")

@export var terminal_caret_blink: bool = true

@export_range(0.1, 2.0, 0.05)
var terminal_caret_blink_interval: float = 0.45


@export_group("Visual")

@export_range(8, 72, 1)
var terminal_font_size: int = 18

@export var text_color: Color = Color(
	0.60,
	1.00,
	0.82,
	1.00
)

@export var placeholder_color: Color = Color(
	0.60,
	1.00,
	0.82,
	0.38
)

@export var caret_color: Color = Color(
	0.72,
	1.00,
	0.88,
	1.00
)

@export var selection_color: Color = Color(
	0.15,
	0.65,
	0.50,
	0.45
)

@export var disabled_color: Color = Color(
	0.45,
	0.65,
	0.58,
	0.55
)

@export var outline_color: Color = Color(
	0.0,
	0.08,
	0.06,
	1.0
)

@export_range(0, 8, 1)
var outline_size: int = 1


var _history: Array[String] = []
var _history_index: int = 0
var _draft_text: String = ""

var _input_enabled: bool = false


func _ready() -> void:
	_configure_line_edit()

	text_submitted.connect(
		_on_text_submitted
	)

	set_input_enabled(false)


# -------------------------------------------------------------------
# PUBLIC API
# -------------------------------------------------------------------

func set_input_enabled(value: bool) -> void:
	_input_enabled = value
	editable = value

	if value:
		focus_mode = Control.FOCUS_ALL
		mouse_filter = Control.MOUSE_FILTER_STOP

		if focus_when_enabled:
			request_terminal_focus()
	else:
		focus_mode = Control.FOCUS_NONE
		mouse_filter = Control.MOUSE_FILTER_IGNORE

		unedit()


func is_input_enabled() -> bool:
	return _input_enabled


func request_terminal_focus() -> void:
	if not _input_enabled:
		return

	if not visible:
		return

	if not is_inside_tree():
		return

	call_deferred(
		"_apply_terminal_focus"
	)


func clear_input() -> void:
	text = ""
	caret_column = 0
	_history_index = _history.size()
	_draft_text = ""


func clear_history() -> void:
	_history.clear()
	_history_index = 0
	_draft_text = ""


func get_history_size() -> int:
	return _history.size()


# -------------------------------------------------------------------
# CONFIGURATION
# -------------------------------------------------------------------

func _configure_line_edit() -> void:
	alignment = HORIZONTAL_ALIGNMENT_LEFT

	placeholder_text = terminal_placeholder
	max_length = command_max_length

	keep_editing_on_text_submit = true

	caret_blink = terminal_caret_blink
	caret_blink_interval = terminal_caret_blink_interval
	caret_force_displayed = false
	caret_mid_grapheme = false

	clear_button_enabled = false
	context_menu_enabled = false
	emoji_menu_enabled = false
	middle_mouse_paste_enabled = false

	selecting_enabled = true
	shortcut_keys_enabled = true
	drag_and_drop_selection_enabled = false
	deselect_on_focus_loss_enabled = true

	expand_to_text_length = false
	virtual_keyboard_enabled = false
	flat = true

	add_theme_font_size_override(
		&"font_size",
		terminal_font_size
	)

	add_theme_color_override(
		&"font_color",
		text_color
	)

	add_theme_color_override(
		&"font_placeholder_color",
		placeholder_color
	)

	add_theme_color_override(
		&"font_uneditable_color",
		disabled_color
	)

	add_theme_color_override(
		&"caret_color",
		caret_color
	)

	add_theme_color_override(
		&"selection_color",
		selection_color
	)

	add_theme_color_override(
		&"font_outline_color",
		outline_color
	)

	add_theme_constant_override(
		&"outline_size",
		outline_size
	)

	add_theme_constant_override(
		&"caret_width",
		2
	)

	var empty_style: StyleBoxEmpty = StyleBoxEmpty.new()

	add_theme_stylebox_override(
		&"normal",
		empty_style
	)

	add_theme_stylebox_override(
		&"focus",
		empty_style
	)

	add_theme_stylebox_override(
		&"read_only",
		empty_style
	)


# -------------------------------------------------------------------
# SUBMISSION
# -------------------------------------------------------------------

func _on_text_submitted(
	submitted_text: String
) -> void:
	if not _input_enabled:
		return

	var command: String = (
		submitted_text.strip_edges()
	)

	text = ""
	caret_column = 0

	if command.is_empty():
		request_terminal_focus()
		return

	_add_history_entry(command)

	command_entered.emit(command)

	request_terminal_focus()


func _add_history_entry(command: String) -> void:
	if (
		not _history.is_empty()
		and _history.back() == command
	):
		_history_index = _history.size()
		_draft_text = ""
		return

	_history.push_back(command)

	while _history.size() > max_history_entries:
		_history.remove_at(0)

	_history_index = _history.size()
	_draft_text = ""


# -------------------------------------------------------------------
# GUI INPUT
# -------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if not _input_enabled:
		return

	var key_event: InputEventKey = (
		event as InputEventKey
	)

	if key_event == null:
		return

	if not key_event.pressed:
		return

	if key_event.echo:
		return

	match key_event.keycode:
		KEY_UP:
			_show_previous_history_entry()
			accept_event()

		KEY_DOWN:
			_show_next_history_entry()
			accept_event()

		KEY_ESCAPE:
			clear_input()
			request_terminal_focus()
			accept_event()


func _show_previous_history_entry() -> void:
	if _history.is_empty():
		return

	if _history_index == _history.size():
		_draft_text = text

	_history_index = maxi(
		_history_index - 1,
		0
	)

	_set_text_with_caret(
		_history[_history_index]
	)


func _show_next_history_entry() -> void:
	if _history.is_empty():
		return

	if _history_index < _history.size() - 1:
		_history_index += 1

		_set_text_with_caret(
			_history[_history_index]
		)

		return

	_history_index = _history.size()

	_set_text_with_caret(
		_draft_text
	)


func _set_text_with_caret(value: String) -> void:
	text = value
	caret_column = text.length()


# -------------------------------------------------------------------
# FOCUS
# -------------------------------------------------------------------

func _apply_terminal_focus() -> void:
	if not _input_enabled:
		return

	if not visible:
		return

	if not is_inside_tree():
		return

	grab_focus()
	edit()

	caret_column = text.length()
