class_name AiConsolePanel
extends PanelBase
## Conversational AI command-console panel.


#region Nodes

@onready var _status_widget: AiStatusWidget = %AiStatusWidget
@onready var _conversation_output: RichTextLabel = %ConversationOutput
@onready var _prompt_input: LineEdit = %PromptInput
@onready var _send_button: HydraButton = %SendButton
@onready var _cancel_button: HydraButton = %CancelButton
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: AiSystemService
var _configuration: AiSystemConfiguration

#endregion


#region Lifecycle

func _ready() -> void:
	super()

	_send_button.pressed.connect(_on_send_button_pressed)
	_cancel_button.pressed.connect(_on_cancel_button_pressed)
	_prompt_input.text_submitted.connect(_on_prompt_submitted)

#endregion


#region Public API

## Binds the panel to AI System.
func bind_service(
	service: AiSystemService,
	configuration: AiSystemConfiguration
) -> void:
	assert(service != null, "AI System service cannot be null.")
	assert(
		configuration != null,
		"AI System configuration cannot be null."
	)

	_disconnect_service()
	_service = service
	_configuration = configuration

	_service.conversation_created.connect(
		_on_conversation_created
	)
	_service.message_added.connect(_on_message_added)
	_service.execution_state_changed.connect(
		_on_execution_state_changed
	)
	_service.completion_received.connect(
		_on_completion_received
	)
	_service.execution_failed.connect(
		_on_execution_failed
	)

	_status_widget.set_provider(
		configuration.provider_id,
		configuration.model_id
	)


## Clears visible conversation output.
func clear_output() -> void:
	_conversation_output.text = ""

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.conversation_created.is_connected(
		_on_conversation_created
	):
		_service.conversation_created.disconnect(
			_on_conversation_created
		)

	if _service.message_added.is_connected(_on_message_added):
		_service.message_added.disconnect(_on_message_added)

	if _service.execution_state_changed.is_connected(
		_on_execution_state_changed
	):
		_service.execution_state_changed.disconnect(
			_on_execution_state_changed
		)

	if _service.completion_received.is_connected(
		_on_completion_received
	):
		_service.completion_received.disconnect(
			_on_completion_received
		)

	if _service.execution_failed.is_connected(
		_on_execution_failed
	):
		_service.execution_failed.disconnect(
			_on_execution_failed
		)


func _submit_prompt(text: String) -> void:
	if _service == null:
		return

	var normalized_text := text.strip_edges()

	if normalized_text.is_empty():
		return

	_error_label.visible = false
	_prompt_input.clear()

	var result := _service.send_message(normalized_text)

	if result.is_failure():
		_on_execution_failed(
			_service.get_active_conversation(),
			result.get_error()
		)


func _append_message(message: AiMessage) -> void:
	var role := String(
		AiMessageRole.to_string_name(
			message.get_role()
		)
	).to_upper()

	var color := "#d6aa48"

	match message.get_role():
		AiMessageRole.Value.SYSTEM:
			color = "#6e8794"
		AiMessageRole.Value.USER:
			color = "#d6aa48"
		AiMessageRole.Value.ASSISTANT:
			color = "#32d8ff"
		AiMessageRole.Value.TOOL:
			color = "#55f2a3"

	_conversation_output.append_text(
		"[color=%s]%s[/color]\n%s\n\n"
		% [
			color,
			role,
			_escape_bbcode(message.get_content()),
		]
	)

	_conversation_output.scroll_to_line(
		_conversation_output.get_line_count()
	)


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")


func _on_send_button_pressed(
	_action_id: StringName
) -> void:
	_submit_prompt(_prompt_input.text)


func _on_cancel_button_pressed(
	_action_id: StringName
) -> void:
	if _service != null:
		_service.cancel_active_request()


func _on_prompt_submitted(text: String) -> void:
	_submit_prompt(text)


func _on_conversation_created(
	conversation: AiConversation
) -> void:
	_conversation_output.text = (
		"[color=#6e8794]CONVERSATION  //  %s[/color]\n\n"
		% conversation.get_title()
	)


func _on_message_added(
	_conversation: AiConversation,
	message: AiMessage
) -> void:
	_append_message(message)


func _on_execution_state_changed(
	_conversation: AiConversation,
	state: AiExecutionState.Value
) -> void:
	_status_widget.set_execution_state(state)


func _on_completion_received(
	conversation: AiConversation,
	_response: AiCompletionResponse
) -> void:
	_status_widget.set_token_usage(
		conversation.get_total_input_tokens(),
		conversation.get_total_output_tokens()
	)


func _on_execution_failed(
	_conversation: AiConversation,
	error: DomainError
) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]AI EXECUTION FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % _escape_bbcode(error.get_message())

#endregion