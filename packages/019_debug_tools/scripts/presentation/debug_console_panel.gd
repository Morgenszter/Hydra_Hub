class_name DebugConsolePanel
extends PanelBase
## Displays logs and executes registered debug commands.


#region Nodes

@onready var _output: RichTextLabel = %Output
@onready var _command_input: LineEdit = %CommandInput
@onready var _execute_button: HydraButton = %ExecuteButton
@onready var _clear_button: HydraButton = %ClearButton
@onready var _status_label: RichTextLabel = %StatusLabel

#endregion


#region State

var _service: DebugToolsService

#endregion


#region Lifecycle

func _ready() -> void:
	super()

	_execute_button.pressed.connect(
		_on_execute_button_pressed
	)
	_clear_button.pressed.connect(
		_on_clear_button_pressed
	)
	_command_input.text_submitted.connect(
		_on_command_submitted
	)

#endregion


#region Public API

## Binds the console to DebugToolsService.
func bind_service(service: DebugToolsService) -> void:
	assert(service != null, "Debug Tools service cannot be null.")

	_disconnect_service()
	_service = service

	_service.log_entry_added.connect(
		_on_log_entry_added
	)
	_service.logs_cleared.connect(
		_on_logs_cleared
	)
	_service.command_executed.connect(
		_on_command_executed
	)

	_render_existing_logs()

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.log_entry_added.is_connected(
		_on_log_entry_added
	):
		_service.log_entry_added.disconnect(
			_on_log_entry_added
		)

	if _service.logs_cleared.is_connected(
		_on_logs_cleared
	):
		_service.logs_cleared.disconnect(
			_on_logs_cleared
		)

	if _service.command_executed.is_connected(
		_on_command_executed
	):
		_service.command_executed.disconnect(
			_on_command_executed
		)


func _render_existing_logs() -> void:
	_output.text = ""

	if _service == null:
		return

	for entry in _service.get_entries():
		_append_entry(entry)


func _submit_command(command_line: String) -> void:
	if _service == null:
		return

	var normalized := command_line.strip_edges()

	if normalized.is_empty():
		return

	_output.append_text(
		"[color=#d6aa48]> %s[/color]\n"
		% _escape_bbcode(normalized)
	)

	_command_input.clear()
	_service.execute_command(normalized)


func _append_entry(entry: DebugLogEntry) -> void:
	var color := DebugLogLevel.to_color(
		entry.get_level()
	).to_html(false)

	_output.append_text(
		"[color=#6e8794][%s][/color] "
		+ "[color=%s]%s[/color] "
		+ "[color=#32d8ff]%s[/color]\n"
	) % [
		DebugLogLevel.to_string_name(
			entry.get_level()
		),
		color,
		String(entry.get_source()).to_upper(),
		_escape_bbcode(entry.get_message()),
	]

	_output.scroll_to_line(
		_output.get_line_count()
	)


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")


func _on_execute_button_pressed(
	_action_id: StringName
) -> void:
	_submit_command(_command_input.text)


func _on_clear_button_pressed(
	_action_id: StringName
) -> void:
	if _service != null:
		_service.clear_logs()

	_output.text = ""


func _on_command_submitted(command_line: String) -> void:
	_submit_command(command_line)


func _on_log_entry_added(entry: DebugLogEntry) -> void:
	_append_entry(entry)


func _on_logs_cleared() -> void:
	_output.text = ""


func _on_command_executed(
	_command_line: String,
	result: Result
) -> void:
	if result.is_failure():
		_status_label.text = (
			"[color=#ff4f62]COMMAND FAILED  //  %s[/color]"
			% _escape_bbcode(
				result.get_error().get_message()
			)
		)
		return

	var value: Variant = result.get_value()

	if value is Dictionary and value.get(&"clear_output", false):
		_output.text = ""
		_status_label.text = (
			"[color=#55f2a3]OUTPUT CLEARED[/color]"
		)
		return

	if value != null:
		_output.append_text(
			"[color=#55f2a3]%s[/color]\n"
			% _escape_bbcode(str(value))
		)

	_status_label.text = (
		"[color=#55f2a3]COMMAND COMPLETED[/color]"
	)

#endregion