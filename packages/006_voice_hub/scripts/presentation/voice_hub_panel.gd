class_name VoiceHubPanel
extends PanelBase
## Desktop panel for controlling Voice Hub interactions.


#region Signals

signal listen_requested()
signal stop_requested()
signal cancel_requested()

#endregion


#region Nodes

@onready var _status_widget: VoiceStatusWidget = %VoiceStatusWidget
@onready var _transcription_label: RichTextLabel = %TranscriptionLabel
@onready var _listen_button: HydraButton = %ListenButton
@onready var _stop_button: HydraButton = %StopButton
@onready var _cancel_button: HydraButton = %CancelButton

#endregion


#region State

var _service: VoiceHubService

#endregion


#region Lifecycle

func _ready() -> void:
	super()

	_listen_button.pressed.connect(
		_on_listen_button_pressed
	)
	_stop_button.pressed.connect(
		_on_stop_button_pressed
	)
	_cancel_button.pressed.connect(
		_on_cancel_button_pressed
	)

#endregion


#region Public API

## Binds the panel to the Voice Hub application service.
func bind_service(service: VoiceHubService) -> void:
	assert(service != null, "Voice Hub service cannot be null.")

	_disconnect_service()
	_service = service

	_service.session_state_changed.connect(
		_on_session_state_changed
	)
	_service.input_level_changed.connect(
		_on_input_level_changed
	)
	_service.transcription_completed.connect(
		_on_transcription_completed
	)
	_service.operation_failed.connect(
		_on_operation_failed
	)


## Clears the displayed transcription.
func clear_transcription() -> void:
	_transcription_label.text = (
		"[color=#40515b]NO TRANSCRIPTION DATA[/color]"
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.session_state_changed.is_connected(
		_on_session_state_changed
	):
		_service.session_state_changed.disconnect(
			_on_session_state_changed
		)

	if _service.input_level_changed.is_connected(
		_on_input_level_changed
	):
		_service.input_level_changed.disconnect(
			_on_input_level_changed
		)

	if _service.transcription_completed.is_connected(
		_on_transcription_completed
	):
		_service.transcription_completed.disconnect(
			_on_transcription_completed
		)

	if _service.operation_failed.is_connected(
		_on_operation_failed
	):
		_service.operation_failed.disconnect(
			_on_operation_failed
		)


func _on_listen_button_pressed(
	_action_id: StringName
) -> void:
	listen_requested.emit()

	if _service == null:
		return

	var result := _service.start_listening()

	if result.is_failure():
		_on_operation_failed(result.get_error())


func _on_stop_button_pressed(
	_action_id: StringName
) -> void:
	stop_requested.emit()

	if _service == null:
		return

	var result := _service.stop_and_transcribe()

	if result.is_failure():
		_on_operation_failed(result.get_error())


func _on_cancel_button_pressed(
	_action_id: StringName
) -> void:
	cancel_requested.emit()

	if _service != null:
		_service.cancel()


func _on_session_state_changed(
	state: VoiceSessionState.Value
) -> void:
	_status_widget.set_session_state(state)


func _on_input_level_changed(level_db: float) -> void:
	_status_widget.set_input_level_db(level_db)


func _on_transcription_completed(
	transcription: VoiceTranscription
) -> void:
	_transcription_label.text = (
		"[color=#32d8ff]%s[/color]\n"
		+ "[color=#6e8794]CONFIDENCE: %d%%  //  PROVIDER: %s[/color]"
	) % [
		transcription.get_text(),
		int(transcription.get_confidence() * 100.0),
		transcription.get_provider_id(),
	]


func _on_operation_failed(error: DomainError) -> void:
	_transcription_label.text = (
		"[color=#ff4f62]VOICE ERROR[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()

#endregion