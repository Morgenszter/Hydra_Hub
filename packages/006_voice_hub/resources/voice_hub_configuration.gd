class_name VoiceHubConfiguration
extends Resource
## Stores runtime configuration for Voice Hub.
##
## Credentials are intentionally excluded from this resource. Secret values
## must be resolved through a secure runtime service.


#region Capture

@export_group("Capture")
@export var capture_enabled: bool = false
@export var input_bus_name: StringName = &"VoiceCapture"
@export_range(8000, 96000, 1000) var sample_rate_hz: int = 48000
@export_range(1, 2, 1) var channel_count: int = 1
@export_range(0.1, 30.0, 0.1) var maximum_capture_seconds: float = 15.0

#endregion


#region Detection

@export_group("Detection")
@export_range(-80.0, 0.0, 0.5) var activation_threshold_db: float = -32.0
@export_range(0.05, 3.0, 0.05) var silence_timeout_seconds: float = 0.75
@export_range(0.05, 2.0, 0.05) var minimum_utterance_seconds: float = 0.25

#endregion


#region Providers

@export_group("Providers")
@export var speech_to_text_provider_id: StringName = &"disabled"
@export var text_to_speech_provider_id: StringName = &"disabled"
@export var language_code: String = "pl-PL"
@export var allow_external_processing: bool = false

#endregion


#region Presentation

@export_group("Presentation")
@export var show_live_level: bool = true
@export var show_transcription_preview: bool = true

#endregion