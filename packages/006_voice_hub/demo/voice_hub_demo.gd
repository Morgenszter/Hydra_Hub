class_name VoiceHubDemo
extends Control
## Demonstrates Voice Hub with disabled providers.
##
## The demo validates panel composition without transmitting audio externally.


#region Nodes

@onready var _panel: VoiceHubPanel = %VoiceHubPanel

#endregion


#region State

var _service: VoiceHubService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = VoiceHubService.new()
	_service.name = "VoiceHubService"
	add_child(_service)

	var configuration := VoiceHubConfiguration.new()
	configuration.capture_enabled = false
	configuration.allow_external_processing = false

	var capture := GodotVoiceCapture.new()
	capture.name = "VoiceCapture"
	add_child(capture)

	var speech_to_text := DisabledSpeechToTextProvider.new()
	var text_to_speech := DisabledTextToSpeechProvider.new()

	var configuration_result := _service.configure(
		configuration,
		capture,
		speech_to_text,
		text_to_speech
	)

	if configuration_result.is_failure():
		push_warning(
			configuration_result.get_error().get_message()
		)

	_panel.bind_service(_service)

#endregion