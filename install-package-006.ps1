#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

function Write-HydraFile {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $destination = Join-Path $RepositoryRoot $RelativePath
    $directory = Split-Path $destination -Parent

    if (-not (Test-Path $directory)) {
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    }

    if ((Test-Path $destination) -and -not $Force) {
        Write-Host "[SKIP]  $RelativePath" -ForegroundColor Yellow
        return
    }

    [System.IO.File]::WriteAllText(
        $destination,
        $Content.TrimStart(),
        $utf8WithoutBom
    )

    Write-Host "[WRITE] $RelativePath" -ForegroundColor Green
}

function Assert-HydraRepository {
    $projectFile = Join-Path $RepositoryRoot "project.godot"

    if (-not (Test-Path $projectFile)) {
        throw "Nie znaleziono project.godot w: $RepositoryRoot"
    }
}

Assert-HydraRepository

$files = [ordered]@{}

$files["packages/006_voice_hub/package.cfg"] = @'
[package]

id="006_voice_hub"
name="Voice Hub"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"004_animation_system",
	"005_fx_system"
)
'@

$files["packages/006_voice_hub/README.md"] = @'
# Package 006 — Voice Hub

Voice Hub owns voice capture state, transcription requests, speech synthesis
requests, provider contracts and the desktop voice-control panel.

The package does not embed provider credentials in scenes, scripts or resources.

## Responsibilities

Voice Hub coordinates microphone capture, speech-to-text providers,
text-to-speech providers and user-facing voice status.

## Privacy

Audio must not be transmitted to an external provider without an explicit
runtime configuration enabling that provider.

## Dependencies

Voice Hub depends on Foundation, Design System, Widget Library, Animation System
and FX System.
'@

$files["packages/006_voice_hub/CHANGELOG.md"] = @'
# Voice Hub changelog

## [0.1.0] - 2026-07-17

### Added

- Added voice session domain model.
- Added voice provider contracts.
- Added transcription and synthesis request models.
- Added local microphone capture service.
- Added Voice Hub application service.
- Added Voice Hub panel and status widget.
- Added demo scene and smoke tests.
'@

$files["packages/006_voice_hub/docs/architecture.md"] = @'
# Voice Hub architecture

Voice Hub is divided into domain, application, infrastructure and presentation
layers.

The domain layer contains provider-independent state and request models.

The application layer coordinates use cases through abstract ports.

The infrastructure layer integrates Godot audio capture and provider adapters.

The presentation layer exposes the current voice state through reusable controls.
'@

$files["packages/006_voice_hub/docs/privacy.md"] = @'
# Voice privacy

Microphone input is disabled by default.

External transmission requires an explicitly configured provider.

Secrets must be loaded from environment variables, operating-system credential
storage or an encrypted settings service.

Raw audio must not be written to disk unless recording has been explicitly
enabled by the user.

Diagnostic logs must not contain raw audio, access tokens or complete
transcriptions marked as private.
'@

$files["packages/006_voice_hub/docs/providers.md"] = @'
# Voice provider contract

A speech-to-text provider receives a VoiceTranscriptionRequest and returns a
Result containing VoiceTranscription.

A text-to-speech provider receives a VoiceSynthesisRequest and returns a Result
containing an AudioStream.

Provider adapters remain replaceable and must not be referenced directly by
presentation classes.
'@

$files["packages/006_voice_hub/resources/voice_hub_configuration.gd"] = @'
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
'@

$files["packages/006_voice_hub/resources/default_voice_hub_configuration.tres"] = @'
[gd_resource type="Resource" script_class="VoiceHubConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/006_voice_hub/resources/voice_hub_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
capture_enabled = false
input_bus_name = &"VoiceCapture"
sample_rate_hz = 48000
channel_count = 1
maximum_capture_seconds = 15.0
activation_threshold_db = -32.0
silence_timeout_seconds = 0.75
minimum_utterance_seconds = 0.25
speech_to_text_provider_id = &"disabled"
text_to_speech_provider_id = &"disabled"
language_code = "pl-PL"
allow_external_processing = false
show_live_level = true
show_transcription_preview = true
'@

$files["packages/006_voice_hub/scripts/domain/voice_session_state.gd"] = @'
class_name VoiceSessionState
extends RefCounted
## Defines stable lifecycle states for a voice interaction session.


#region State

enum Value {
	IDLE,
	ARMED,
	LISTENING,
	PROCESSING,
	SPEAKING,
	COMPLETED,
	CANCELLED,
	FAILED,
}

#endregion


#region Public API

## Returns a stable lowercase identifier for the supplied state.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.IDLE:
			return &"idle"
		Value.ARMED:
			return &"armed"
		Value.LISTENING:
			return &"listening"
		Value.PROCESSING:
			return &"processing"
		Value.SPEAKING:
			return &"speaking"
		Value.COMPLETED:
			return &"completed"
		Value.CANCELLED:
			return &"cancelled"
		Value.FAILED:
			return &"failed"
		_:
			return &"unknown"

#endregion
'@

$files["packages/006_voice_hub/scripts/domain/voice_transcription_request.gd"] = @'
class_name VoiceTranscriptionRequest
extends RefCounted
## Represents an immutable speech-to-text request.


#region State

var _request_id: StringName
var _audio_frames: PackedVector2Array
var _sample_rate_hz: int
var _language_code: String
var _correlation_id: StringName

#endregion


#region Construction

## Creates a transcription request from captured stereo audio frames.
func _init(
	audio_frames: PackedVector2Array,
	sample_rate_hz: int,
	language_code: String,
	correlation_id: StringName = &""
) -> void:
	assert(
		not audio_frames.is_empty(),
		"VoiceTranscriptionRequest requires audio frames."
	)
	assert(
		sample_rate_hz > 0,
		"VoiceTranscriptionRequest requires a positive sample rate."
	)
	assert(
		not language_code.strip_edges().is_empty(),
		"VoiceTranscriptionRequest requires a language code."
	)

	_request_id = StringName(UUID.v4())
	_audio_frames = audio_frames.duplicate()
	_sample_rate_hz = sample_rate_hz
	_language_code = language_code.strip_edges()
	_correlation_id = correlation_id

	if _correlation_id.is_empty():
		_correlation_id = _request_id

#endregion


#region Public API

## Returns the unique request identifier.
func get_request_id() -> StringName:
	return _request_id


## Returns a defensive copy of captured audio frames.
func get_audio_frames() -> PackedVector2Array:
	return _audio_frames.duplicate()


## Returns the source audio sample rate.
func get_sample_rate_hz() -> int:
	return _sample_rate_hz


## Returns the requested language code.
func get_language_code() -> String:
	return _language_code


## Returns the distributed tracing correlation identifier.
func get_correlation_id() -> StringName:
	return _correlation_id


## Returns the approximate audio duration in seconds.
func get_duration_seconds() -> float:
	return float(_audio_frames.size()) / float(_sample_rate_hz)

#endregion
'@

$files["packages/006_voice_hub/scripts/domain/voice_transcription.gd"] = @'
class_name VoiceTranscription
extends RefCounted
## Represents an immutable speech-to-text result.


#region State

var _text: String
var _language_code: String
var _confidence: float
var _provider_id: StringName
var _completed_at_unix_ms: int

#endregion


#region Construction

## Creates a transcription result.
func _init(
	text: String,
	language_code: String,
	confidence: float,
	provider_id: StringName
) -> void:
	assert(
		not text.strip_edges().is_empty(),
		"VoiceTranscription requires non-empty text."
	)
	assert(
		confidence >= 0.0 and confidence <= 1.0,
		"VoiceTranscription confidence must be between zero and one."
	)
	assert(
		not provider_id.is_empty(),
		"VoiceTranscription requires a provider identifier."
	)

	_text = text.strip_edges()
	_language_code = language_code.strip_edges()
	_confidence = confidence
	_provider_id = provider_id
	_completed_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)

#endregion


#region Public API

## Returns the normalized transcription text.
func get_text() -> String:
	return _text


## Returns the detected or requested language code.
func get_language_code() -> String:
	return _language_code


## Returns the provider confidence from zero to one.
func get_confidence() -> float:
	return _confidence


## Returns the provider identifier.
func get_provider_id() -> StringName:
	return _provider_id


## Returns the completion timestamp as Unix milliseconds.
func get_completed_at_unix_ms() -> int:
	return _completed_at_unix_ms

#endregion
'@

$files["packages/006_voice_hub/scripts/domain/voice_synthesis_request.gd"] = @'
class_name VoiceSynthesisRequest
extends RefCounted
## Represents an immutable text-to-speech request.


#region State

var _request_id: StringName
var _text: String
var _language_code: String
var _voice_id: StringName
var _speech_rate: float
var _correlation_id: StringName

#endregion


#region Construction

## Creates a synthesis request.
func _init(
	text: String,
	language_code: String,
	voice_id: StringName,
	speech_rate: float = 1.0,
	correlation_id: StringName = &""
) -> void:
	assert(
		not text.strip_edges().is_empty(),
		"VoiceSynthesisRequest requires text."
	)
	assert(
		not language_code.strip_edges().is_empty(),
		"VoiceSynthesisRequest requires a language code."
	)
	assert(
		not voice_id.is_empty(),
		"VoiceSynthesisRequest requires a voice identifier."
	)
	assert(
		speech_rate >= 0.5 and speech_rate <= 2.0,
		"VoiceSynthesisRequest speech rate must be between 0.5 and 2.0."
	)

	_request_id = StringName(UUID.v4())
	_text = text.strip_edges()
	_language_code = language_code.strip_edges()
	_voice_id = voice_id
	_speech_rate = speech_rate
	_correlation_id = correlation_id

	if _correlation_id.is_empty():
		_correlation_id = _request_id

#endregion


#region Public API

## Returns the unique request identifier.
func get_request_id() -> StringName:
	return _request_id


## Returns the text to synthesize.
func get_text() -> String:
	return _text


## Returns the requested language code.
func get_language_code() -> String:
	return _language_code


## Returns the requested provider voice identifier.
func get_voice_id() -> StringName:
	return _voice_id


## Returns the speech-rate multiplier.
func get_speech_rate() -> float:
	return _speech_rate


## Returns the distributed tracing correlation identifier.
func get_correlation_id() -> StringName:
	return _correlation_id

#endregion
'@

$files["packages/006_voice_hub/scripts/domain/voice_session.gd"] = @'
class_name VoiceSession
extends AggregateRoot
## Represents one complete user voice interaction.
##
## VoiceSession owns the interaction state and publishes immutable domain
## events whenever its lifecycle changes.


#region Event names

const EVENT_STATE_CHANGED: StringName = \
	&"hydra.voice.session.state_changed"
const EVENT_TRANSCRIPTION_COMPLETED: StringName = \
	&"hydra.voice.session.transcription_completed"
const EVENT_SESSION_FAILED: StringName = \
	&"hydra.voice.session.failed"

#endregion


#region State

var _state: VoiceSessionState.Value = VoiceSessionState.Value.IDLE
var _transcription: VoiceTranscription
var _failure: DomainError

#endregion


#region Construction

## Creates a new idle voice session.
func _init(id: EntityId) -> void:
	super(id)

#endregion


#region Public API

## Returns the current session state.
func get_state() -> VoiceSessionState.Value:
	return _state


## Returns the completed transcription, when available.
func get_transcription() -> VoiceTranscription:
	return _transcription


## Returns the current failure, when available.
func get_failure() -> DomainError:
	return _failure


## Arms the session for audio capture.
func arm() -> Result:
	return _transition(
		VoiceSessionState.Value.ARMED,
		[
			VoiceSessionState.Value.IDLE,
			VoiceSessionState.Value.COMPLETED,
			VoiceSessionState.Value.CANCELLED,
		]
	)


## Starts microphone capture.
func start_listening() -> Result:
	return _transition(
		VoiceSessionState.Value.LISTENING,
		[VoiceSessionState.Value.ARMED]
	)


## Marks audio as captured and starts processing.
func start_processing() -> Result:
	return _transition(
		VoiceSessionState.Value.PROCESSING,
		[VoiceSessionState.Value.LISTENING]
	)


## Completes speech-to-text processing.
func complete_transcription(
	transcription: VoiceTranscription
) -> Result:
	if transcription == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Voice transcription cannot be null."
			)
		)

	if _state != VoiceSessionState.Value.PROCESSING:
		return _invalid_transition(
			VoiceSessionState.Value.COMPLETED
		)

	_transcription = transcription
	_failure = null
	_state = VoiceSessionState.Value.COMPLETED
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_TRANSCRIPTION_COMPLETED,
			{
				&"session_id": get_id().as_string(),
				&"text": transcription.get_text(),
				&"language_code": transcription.get_language_code(),
				&"confidence": transcription.get_confidence(),
				&"provider_id": transcription.get_provider_id(),
			}
		)
	)

	_record_state_changed_event()

	return Result.success()


## Marks synthesized voice output as active.
func start_speaking() -> Result:
	return _transition(
		VoiceSessionState.Value.SPEAKING,
		[
			VoiceSessionState.Value.IDLE,
			VoiceSessionState.Value.COMPLETED,
		]
	)


## Completes synthesized voice output.
func complete_speaking() -> Result:
	return _transition(
		VoiceSessionState.Value.COMPLETED,
		[VoiceSessionState.Value.SPEAKING]
	)


## Cancels the current interaction.
func cancel() -> Result:
	if _state == VoiceSessionState.Value.CANCELLED:
		return Result.success()

	if _state == VoiceSessionState.Value.FAILED:
		return _invalid_transition(
			VoiceSessionState.Value.CANCELLED
		)

	_state = VoiceSessionState.Value.CANCELLED
	increment_version()
	_record_state_changed_event()

	return Result.success()


## Records a structured session failure.
func fail(error: DomainError) -> Result:
	if error == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Voice session failure cannot be null."
			)
		)

	_failure = error
	_state = VoiceSessionState.Value.FAILED
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_SESSION_FAILED,
			{
				&"session_id": get_id().as_string(),
				&"error": error.to_dictionary(),
			}
		)
	)

	_record_state_changed_event()

	return Result.success()

#endregion


#region Private methods

func _transition(
	next_state: VoiceSessionState.Value,
	allowed_states: Array[VoiceSessionState.Value]
) -> Result:
	if _state not in allowed_states:
		return _invalid_transition(next_state)

	_state = next_state
	increment_version()
	_record_state_changed_event()

	return Result.success()


func _invalid_transition(
	next_state: VoiceSessionState.Value
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Voice session state transition is invalid.",
			{
				&"current_state": VoiceSessionState.to_string_name(
					_state
				),
				&"requested_state": VoiceSessionState.to_string_name(
					next_state
				),
			}
		)
	)


func _record_state_changed_event() -> void:
	_record_domain_event(
		DomainEvent.new(
			EVENT_STATE_CHANGED,
			{
				&"session_id": get_id().as_string(),
				&"state": VoiceSessionState.to_string_name(_state),
			}
		)
	)

#endregion
'@

$files["packages/006_voice_hub/scripts/contracts/voice_capture_port.gd"] = @'
@abstract
class_name VoiceCapturePort
extends Node
## Defines the microphone capture boundary used by Voice Hub.


#region Signals

signal capture_started()
signal capture_stopped(audio_frames: PackedVector2Array)
signal input_level_changed(level_db: float)
signal capture_failed(error: DomainError)

#endregion


#region Public API

## Configures the capture adapter.
@abstract
func configure(configuration: VoiceHubConfiguration) -> Result


## Starts microphone capture.
@abstract
func start_capture() -> Result


## Stops capture and returns available audio frames.
@abstract
func stop_capture() -> Result


## Cancels capture and discards buffered frames.
@abstract
func cancel_capture() -> void


## Returns `true` while audio capture is active.
@abstract
func is_capturing() -> bool

#endregion
'@

$files["packages/006_voice_hub/scripts/contracts/speech_to_text_port.gd"] = @'
@abstract
class_name SpeechToTextPort
extends RefCounted
## Defines a provider-independent speech-to-text boundary.


#region Public API

## Returns the stable provider identifier.
@abstract
func get_provider_id() -> StringName


## Returns `true` when the provider is configured and available.
@abstract
func is_available() -> bool


## Transcribes captured speech.
@abstract
func transcribe(
	request: VoiceTranscriptionRequest
) -> Result

#endregion
'@

$files["packages/006_voice_hub/scripts/contracts/text_to_speech_port.gd"] = @'
@abstract
class_name TextToSpeechPort
extends RefCounted
## Defines a provider-independent text-to-speech boundary.


#region Public API

## Returns the stable provider identifier.
@abstract
func get_provider_id() -> StringName


## Returns `true` when the provider is configured and available.
@abstract
func is_available() -> bool


## Synthesizes speech and returns an AudioStream in a Result.
@abstract
func synthesize(
	request: VoiceSynthesisRequest
) -> Result

#endregion
'@

$files["packages/006_voice_hub/scripts/infrastructure/godot_voice_capture.gd"] = @'
class_name GodotVoiceCapture
extends VoiceCapturePort
## Captures microphone audio through an AudioEffectCapture instance.
##
## The project must contain an audio bus matching the configured bus name and
## that bus must contain AudioEffectCapture as its first effect.


#region Constants

const CAPTURE_EFFECT_INDEX: int = 0

#endregion


#region State

var _configuration: VoiceHubConfiguration
var _capture_effect: AudioEffectCapture
var _capturing: bool = false
var _captured_frames: PackedVector2Array = PackedVector2Array()

#endregion


#region Lifecycle

func _process(_delta: float) -> void:
	if not _capturing or _capture_effect == null:
		return

	var available_frames := _capture_effect.get_frames_available()

	if available_frames <= 0:
		return

	var frames := _capture_effect.get_buffer(available_frames)
	_append_frames(frames)
	_emit_input_level(frames)
	_enforce_duration_limit()

#endregion


#region VoiceCapturePort

func configure(configuration: VoiceHubConfiguration) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Voice capture configuration cannot be null."
			)
		)

	var bus_index := AudioServer.get_bus_index(
		configuration.input_bus_name
	)

	if bus_index < 0:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Voice capture audio bus does not exist.",
				{
					&"bus_name": configuration.input_bus_name,
				}
			)
		)

	var effect := AudioServer.get_bus_effect(
		bus_index,
		CAPTURE_EFFECT_INDEX
	)

	if not effect is AudioEffectCapture:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Voice capture bus requires AudioEffectCapture.",
				{
					&"bus_name": configuration.input_bus_name,
					&"effect_index": CAPTURE_EFFECT_INDEX,
				}
			)
		)

	_configuration = configuration
	_capture_effect = effect as AudioEffectCapture

	return Result.success()


func start_capture() -> Result:
	if _configuration == null or _capture_effect == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Voice capture service is not configured."
			)
		)

	if _capturing:
		return Result.success()

	_captured_frames = PackedVector2Array()
	_capture_effect.clear_buffer()
	_capturing = true
	set_process(true)
	capture_started.emit()

	return Result.success()


func stop_capture() -> Result:
	if not _capturing:
		return Result.success(
			_captured_frames.duplicate()
		)

	_drain_capture_buffer()
	_capturing = false
	set_process(false)

	var result_frames := _captured_frames.duplicate()
	capture_stopped.emit(result_frames)

	return Result.success(result_frames)


func cancel_capture() -> void:
	_capturing = false
	set_process(false)
	_captured_frames = PackedVector2Array()

	if _capture_effect != null:
		_capture_effect.clear_buffer()


func is_capturing() -> bool:
	return _capturing

#endregion


#region Private methods

func _drain_capture_buffer() -> void:
	if _capture_effect == null:
		return

	var available_frames := _capture_effect.get_frames_available()

	if available_frames > 0:
		_append_frames(
			_capture_effect.get_buffer(available_frames)
		)


func _append_frames(frames: PackedVector2Array) -> void:
	_captured_frames.append_array(frames)


func _emit_input_level(frames: PackedVector2Array) -> void:
	if frames.is_empty():
		return

	var peak := 0.0

	for frame in frames:
		peak = maxf(
			peak,
			maxf(absf(frame.x), absf(frame.y))
		)

	var level_db := linear_to_db(maxf(peak, 0.000001))
	input_level_changed.emit(level_db)


func _enforce_duration_limit() -> void:
	var maximum_frames := int(
		_configuration.maximum_capture_seconds
		* float(_configuration.sample_rate_hz)
	)

	if _captured_frames.size() < maximum_frames:
		return

	stop_capture()

#endregion
'@

$files["packages/006_voice_hub/scripts/infrastructure/disabled_speech_to_text_provider.gd"] = @'
class_name DisabledSpeechToTextProvider
extends SpeechToTextPort
## Safe provider used when speech-to-text processing is disabled.


#region Constants

const PROVIDER_ID: StringName = &"disabled"

#endregion


#region SpeechToTextPort

func get_provider_id() -> StringName:
	return PROVIDER_ID


func is_available() -> bool:
	return false


func transcribe(
	_request: VoiceTranscriptionRequest
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Speech-to-text provider is disabled.",
			{
				&"provider_id": PROVIDER_ID,
			}
		)
	)

#endregion
'@

$files["packages/006_voice_hub/scripts/infrastructure/disabled_text_to_speech_provider.gd"] = @'
class_name DisabledTextToSpeechProvider
extends TextToSpeechPort
## Safe provider used when text-to-speech processing is disabled.


#region Constants

const PROVIDER_ID: StringName = &"disabled"

#endregion


#region TextToSpeechPort

func get_provider_id() -> StringName:
	return PROVIDER_ID


func is_available() -> bool:
	return false


func synthesize(
	_request: VoiceSynthesisRequest
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Text-to-speech provider is disabled.",
			{
				&"provider_id": PROVIDER_ID,
			}
		)
	)

#endregion
'@

$files["packages/006_voice_hub/scripts/application/voice_hub_service.gd"] = @'
class_name VoiceHubService
extends Node
## Coordinates voice capture, transcription and speech synthesis.
##
## Provider implementations are injected explicitly. Presentation classes
## communicate with this service through its public methods and signals.


#region Signals

signal session_state_changed(
	state: VoiceSessionState.Value
)
signal input_level_changed(level_db: float)
signal transcription_completed(
	transcription: VoiceTranscription
)
signal speech_started()
signal speech_completed()
signal operation_failed(error: DomainError)

#endregion


#region State

var _configuration: VoiceHubConfiguration
var _capture: VoiceCapturePort
var _speech_to_text: SpeechToTextPort
var _text_to_speech: TextToSpeechPort
var _session: VoiceSession
var _speech_player: AudioStreamPlayer

#endregion


#region Lifecycle

func _ready() -> void:
	_speech_player = AudioStreamPlayer.new()
	_speech_player.name = "VoiceSpeechPlayer"
	add_child(_speech_player)

	_speech_player.finished.connect(
		_on_speech_finished
	)

#endregion


#region Public API

## Configures Voice Hub and injects provider implementations.
func configure(
	configuration: VoiceHubConfiguration,
	capture: VoiceCapturePort,
	speech_to_text: SpeechToTextPort,
	text_to_speech: TextToSpeechPort
) -> Result:
	if configuration == null:
		return _failure(
			HydraErrors.VALUE_REQUIRED,
			"Voice Hub configuration cannot be null."
		)

	if capture == null:
		return _failure(
			HydraErrors.VALUE_REQUIRED,
			"Voice capture service cannot be null."
		)

	if speech_to_text == null:
		return _failure(
			HydraErrors.VALUE_REQUIRED,
			"Speech-to-text provider cannot be null."
		)

	if text_to_speech == null:
		return _failure(
			HydraErrors.VALUE_REQUIRED,
			"Text-to-speech provider cannot be null."
		)

	var capture_result := capture.configure(configuration)

	if capture_result.is_failure():
		return capture_result

	_disconnect_capture_signals()

	_configuration = configuration
	_capture = capture
	_speech_to_text = speech_to_text
	_text_to_speech = text_to_speech

	_connect_capture_signals()

	return Result.success()


## Creates and arms a new voice session.
func arm_session() -> Result:
	_session = VoiceSession.new(EntityId.generate())

	var result := _session.arm()
	_publish_session_events()
	_emit_current_state()

	return result


## Starts microphone capture for the active session.
func start_listening() -> Result:
	if _session == null:
		var arm_result := arm_session()

		if arm_result.is_failure():
			return arm_result

	var transition_result := _session.start_listening()

	if transition_result.is_failure():
		return transition_result

	var capture_result := _capture.start_capture()

	if capture_result.is_failure():
		_session.fail(capture_result.get_error())
		_publish_session_events()
		_emit_current_state()
		operation_failed.emit(capture_result.get_error())

		return capture_result

	_publish_session_events()
	_emit_current_state()

	return Result.success()


## Stops capture and synchronously invokes the configured transcription provider.
func stop_and_transcribe() -> Result:
	if _session == null:
		return _failure(
			HydraErrors.INVALID_STATE,
			"No active voice session exists."
		)

	var processing_result := _session.start_processing()

	if processing_result.is_failure():
		return processing_result

	_publish_session_events()
	_emit_current_state()

	var capture_result := _capture.stop_capture()

	if capture_result.is_failure():
		return _fail_session(capture_result.get_error())

	var frames: PackedVector2Array = capture_result.get_value()

	if frames.is_empty():
		return _fail_session(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Voice capture did not return audio frames."
			)
		)

	if (
		not _configuration.allow_external_processing
		and _speech_to_text.get_provider_id() != &"local"
	):
		return _fail_session(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"External voice processing is disabled.",
				{
					&"provider_id":
						_speech_to_text.get_provider_id(),
				}
			)
		)

	var request := VoiceTranscriptionRequest.new(
		frames,
		_configuration.sample_rate_hz,
		_configuration.language_code,
		_session.get_id().get_value()
	)

	var transcription_result := _speech_to_text.transcribe(request)

	if transcription_result.is_failure():
		return _fail_session(
			transcription_result.get_error()
		)

	var transcription: VoiceTranscription = \
		transcription_result.get_value()

	var completion_result := _session.complete_transcription(
		transcription
	)

	if completion_result.is_failure():
		return completion_result

	_publish_session_events()
	_emit_current_state()
	transcription_completed.emit(transcription)

	return Result.success(transcription)


## Synthesizes and plays speech using the configured provider.
func speak(
	text: String,
	voice_id: StringName = &"default",
	speech_rate: float = 1.0
) -> Result:
	if _configuration == null:
		return _failure(
			HydraErrors.INVALID_STATE,
			"Voice Hub is not configured."
		)

	if (
		not _configuration.allow_external_processing
		and _text_to_speech.get_provider_id() != &"local"
	):
		return _failure(
			HydraErrors.INVALID_STATE,
			"External voice processing is disabled."
		)

	if _session == null:
		_session = VoiceSession.new(EntityId.generate())

	var request := VoiceSynthesisRequest.new(
		text,
		_configuration.language_code,
		voice_id,
		speech_rate,
		_session.get_id().get_value()
	)

	var synthesis_result := _text_to_speech.synthesize(request)

	if synthesis_result.is_failure():
		return _fail_session(
			synthesis_result.get_error()
		)

	var stream: AudioStream = synthesis_result.get_value()

	if stream == null:
		return _fail_session(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Text-to-speech provider returned no audio stream."
			)
		)

	var state_result := _session.start_speaking()

	if state_result.is_failure():
		return state_result

	_speech_player.stream = stream
	_speech_player.play()

	_publish_session_events()
	_emit_current_state()
	speech_started.emit()

	return Result.success()


## Cancels the active voice operation.
func cancel() -> Result:
	if _capture != null:
		_capture.cancel_capture()

	if _speech_player != null:
		_speech_player.stop()

	if _session == null:
		return Result.success()

	var result := _session.cancel()
	_publish_session_events()
	_emit_current_state()

	return result


## Returns the active session.
func get_session() -> VoiceSession:
	return _session

#endregion


#region Private methods

func _connect_capture_signals() -> void:
	if _capture == null:
		return

	if not _capture.input_level_changed.is_connected(
		_on_input_level_changed
	):
		_capture.input_level_changed.connect(
			_on_input_level_changed
		)

	if not _capture.capture_failed.is_connected(
		_on_capture_failed
	):
		_capture.capture_failed.connect(
			_on_capture_failed
		)


func _disconnect_capture_signals() -> void:
	if _capture == null:
		return

	if _capture.input_level_changed.is_connected(
		_on_input_level_changed
	):
		_capture.input_level_changed.disconnect(
			_on_input_level_changed
		)

	if _capture.capture_failed.is_connected(
		_on_capture_failed
	):
		_capture.capture_failed.disconnect(
			_on_capture_failed
		)


func _publish_session_events() -> void:
	if _session == null:
		return

	if not Engine.has_singleton("EventBus"):
		_session.clear_domain_events()
		return

	var event_bus := Engine.get_singleton("EventBus")

	for event in _session.pull_domain_events():
		event_bus.publish(event)


func _emit_current_state() -> void:
	if _session == null:
		return

	session_state_changed.emit(_session.get_state())


func _failure(
	code: StringName,
	message: String
) -> Result:
	var error := DomainError.new(code, message)
	operation_failed.emit(error)

	return Result.failure(error)


func _fail_session(error: DomainError) -> Result:
	if _session != null:
		_session.fail(error)
		_publish_session_events()
		_emit_current_state()

	operation_failed.emit(error)

	return Result.failure(error)


func _on_input_level_changed(level_db: float) -> void:
	input_level_changed.emit(level_db)


func _on_capture_failed(error: DomainError) -> void:
	_fail_session(error)


func _on_speech_finished() -> void:
	if _session != null:
		_session.complete_speaking()
		_publish_session_events()
		_emit_current_state()

	speech_completed.emit()

#endregion
'@

$files["packages/006_voice_hub/scripts/presentation/voice_status_widget.gd"] = @'
class_name VoiceStatusWidget
extends WidgetBase
## Displays the current Voice Hub state and microphone input level.


#region Constants

const MINIMUM_LEVEL_DB: float = -60.0
const MAXIMUM_LEVEL_DB: float = 0.0

#endregion


#region Exported properties

@export var idle_text: String = "VOICE LINK STANDBY"

#endregion


#region Nodes

@onready var _state_label: RichTextLabel = %StateLabel
@onready var _level_fill: ColorRect = %LevelFill
@onready var _status_indicator: ColorRect = %StatusIndicator

#endregion


#region State

var _state: VoiceSessionState.Value = VoiceSessionState.Value.IDLE
var _input_level_db: float = MINIMUM_LEVEL_DB

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	_refresh_state()
	_refresh_level()

#endregion


#region Public API

## Updates the displayed session state.
func set_session_state(
	state: VoiceSessionState.Value
) -> void:
	_state = state
	_refresh_state()


## Updates the displayed microphone level.
func set_input_level_db(level_db: float) -> void:
	_input_level_db = clampf(
		level_db,
		MINIMUM_LEVEL_DB,
		MAXIMUM_LEVEL_DB
	)
	_refresh_level()

#endregion


#region Private methods

func _refresh_state() -> void:
	if not is_node_ready():
		return

	var state_name := VoiceSessionState.to_string_name(
		_state
	)

	_state_label.text = (
		idle_text
		if _state == VoiceSessionState.Value.IDLE
		else "VOICE LINK  //  %s" % String(state_name).to_upper()
	)

	_status_indicator.color = _get_state_color()


func _refresh_level() -> void:
	if not is_node_ready():
		return

	var normalized_level := inverse_lerp(
		MINIMUM_LEVEL_DB,
		MAXIMUM_LEVEL_DB,
		_input_level_db
	)

	_level_fill.scale.x = clampf(
		normalized_level,
		0.0,
		1.0
	)


func _get_state_color() -> Color:
	match _state:
		VoiceSessionState.Value.IDLE:
			return Color("#40515b")
		VoiceSessionState.Value.ARMED:
			return Color("#d6aa48")
		VoiceSessionState.Value.LISTENING:
			return Color("#32d8ff")
		VoiceSessionState.Value.PROCESSING:
			return Color("#ffbf47")
		VoiceSessionState.Value.SPEAKING:
			return Color("#55f2a3")
		VoiceSessionState.Value.COMPLETED:
			return Color("#55f2a3")
		VoiceSessionState.Value.CANCELLED:
			return Color("#40515b")
		VoiceSessionState.Value.FAILED:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion
'@

$files["packages/006_voice_hub/scripts/presentation/voice_hub_panel.gd"] = @'
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
'@

$files["packages/006_voice_hub/scenes/voice_status_widget.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/006_voice_hub/scripts/presentation/voice_status_widget.gd" id="1"]

[node name="VoiceStatusWidget" type="Control"]
custom_minimum_size = Vector2(640, 92)
layout_mode = 3
anchors_preset = 0
offset_right = 640.0
offset_bottom = 92.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"voice_status_widget"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.027451, 0.0901961, 0.133333, 0.92)

[node name="StatusIndicator" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 20.0
offset_top = 20.0
offset_right = 34.0
offset_bottom = 72.0
mouse_filter = 2
color = Color(0.25098, 0.317647, 0.356863, 1)

[node name="StateLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 14.0
offset_right = 612.0
offset_bottom = 48.0
mouse_filter = 2
bbcode_enabled = true
text = "[color=#32d8ff]VOICE LINK STANDBY[/color]"
fit_content = true
scroll_active = false

[node name="LevelTrack" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 58.0
offset_right = 612.0
offset_bottom = 68.0
mouse_filter = 2
color = Color(0.0705882, 0.145098, 0.180392, 1)

[node name="LevelFill" type="ColorRect" parent="LevelTrack"]
unique_name_in_owner = true
layout_mode = 0
offset_right = 558.0
offset_bottom = 10.0
mouse_filter = 2
color = Color(0.196078, 0.847059, 1, 1)
scale = Vector2(0, 1)
'@

$files["packages/006_voice_hub/scenes/voice_hub_panel.tscn"] = @'
[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://packages/006_voice_hub/scripts/presentation/voice_hub_panel.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/006_voice_hub/scenes/voice_status_widget.tscn" id="2"]
[ext_resource type="PackedScene" path="res://packages/003_widget_library/scenes/hydra_button.tscn" id="3"]

[node name="VoiceHubPanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 920.0
offset_bottom = 620.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"voice_hub_panel"
starts_open = true

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.0117647, 0.0313725, 0.0509804, 0.96)

[node name="HeaderAccent" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 24.0
offset_top = 24.0
offset_right = 30.0
offset_bottom = 88.0
mouse_filter = 2
color = Color(0.839216, 0.666667, 0.282353, 1)

[node name="Title" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 48.0
offset_top = 22.0
offset_right = 660.0
offset_bottom = 62.0
mouse_filter = 2
bbcode_enabled = true
text = "[font_size=28][color=#32d8ff]VOICE HUB[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 48.0
offset_top = 62.0
offset_right = 760.0
offset_bottom = 92.0
mouse_filter = 2
bbcode_enabled = true
text = "[color=#6e8794]TACTICAL VOICE INTERFACE  //  CHANNEL 006[/color]"
fit_content = true
scroll_active = false

[node name="VoiceStatusWidget" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 48.0
offset_top = 122.0
offset_right = 688.0
offset_bottom = 214.0

[node name="TranscriptionFrame" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 48.0
offset_top = 242.0
offset_right = 872.0
offset_bottom = 450.0
mouse_filter = 2
color = Color(0.027451, 0.0901961, 0.133333, 0.72)

[node name="TranscriptionTitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 68.0
offset_top = 260.0
offset_right = 840.0
offset_bottom = 294.0
mouse_filter = 2
bbcode_enabled = true
text = "[color=#d6aa48]TRANSCRIPTION BUFFER[/color]"
fit_content = true
scroll_active = false

[node name="TranscriptionLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 68.0
offset_top = 306.0
offset_right = 848.0
offset_bottom = 426.0
mouse_filter = 2
bbcode_enabled = true
text = "[color=#40515b]NO TRANSCRIPTION DATA[/color]"
scroll_active = true

[node name="ListenButton" parent="." instance=ExtResource("3")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 48.0
offset_top = 486.0
offset_right = 304.0
offset_bottom = 550.0
action_id = &"voice_listen"
text = "START LISTENING"

[node name="StopButton" parent="." instance=ExtResource("3")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 332.0
offset_top = 486.0
offset_right = 588.0
offset_bottom = 550.0
action_id = &"voice_stop"
text = "STOP / PROCESS"
accent_color = Color(0.839216, 0.666667, 0.282353, 1)

[node name="CancelButton" parent="." instance=ExtResource("3")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 616.0
offset_top = 486.0
offset_right = 872.0
offset_bottom = 550.0
action_id = &"voice_cancel"
text = "CANCEL"
accent_color = Color(1, 0.309804, 0.384314, 1)
'@

$files["packages/006_voice_hub/demo/voice_hub_demo.gd"] = @'
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
'@

$files["packages/006_voice_hub/demo/voice_hub_demo.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/006_voice_hub/demo/voice_hub_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/006_voice_hub/scenes/voice_hub_panel.tscn" id="2"]

[node name="VoiceHubDemo" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.00392157, 0.0117647, 0.0196078, 1)

[node name="VoiceHubPanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 500.0
offset_top = 210.0
offset_right = 1420.0
offset_bottom = 830.0
'@

$files["packages/006_voice_hub/tests/unit/test_voice_session.gd"] = @'
class_name VoiceSessionTest
extends RefCounted
## Provides executable VoiceSession domain tests.


#region Tests

static func run() -> void:
	_test_valid_capture_lifecycle()
	_test_invalid_transition()
	_test_failure_state()


static func _test_valid_capture_lifecycle() -> void:
	var session := VoiceSession.new(EntityId.generate())

	assert(session.arm().is_success())
	assert(
		session.get_state()
		== VoiceSessionState.Value.ARMED
	)

	assert(session.start_listening().is_success())
	assert(
		session.get_state()
		== VoiceSessionState.Value.LISTENING
	)

	assert(session.start_processing().is_success())

	var transcription := VoiceTranscription.new(
		"Test transcription",
		"en-US",
		0.95,
		&"test_provider"
	)

	assert(
		session.complete_transcription(
			transcription
		).is_success()
	)
	assert(
		session.get_state()
		== VoiceSessionState.Value.COMPLETED
	)
	assert(session.get_transcription() == transcription)
	assert(not session.pull_domain_events().is_empty())


static func _test_invalid_transition() -> void:
	var session := VoiceSession.new(EntityId.generate())
	var result := session.start_processing()

	assert(result.is_failure())
	assert(
		result.get_error().get_code()
		== HydraErrors.INVALID_STATE
	)


static func _test_failure_state() -> void:
	var session := VoiceSession.new(EntityId.generate())
	var error := DomainError.new(
		HydraErrors.UNKNOWN,
		"Test failure."
	)

	assert(session.fail(error).is_success())
	assert(
		session.get_state()
		== VoiceSessionState.Value.FAILED
	)
	assert(session.get_failure() == error)

#endregion
'@

$files["packages/006_voice_hub/tests/unit/test_voice_requests.gd"] = @'
class_name VoiceRequestsTest
extends RefCounted
## Provides executable tests for voice request models.


#region Tests

static func run() -> void:
	_test_transcription_request()
	_test_synthesis_request()


static func _test_transcription_request() -> void:
	var frames := PackedVector2Array([
		Vector2(0.1, 0.1),
		Vector2(0.2, 0.2),
	])

	var request := VoiceTranscriptionRequest.new(
		frames,
		48000,
		"pl-PL"
	)

	assert(not request.get_request_id().is_empty())
	assert(request.get_audio_frames().size() == 2)
	assert(request.get_sample_rate_hz() == 48000)
	assert(request.get_language_code() == "pl-PL")


static func _test_synthesis_request() -> void:
	var request := VoiceSynthesisRequest.new(
		"System operational.",
		"en-US",
		&"default",
		1.0
	)

	assert(not request.get_request_id().is_empty())
	assert(request.get_text() == "System operational.")
	assert(request.get_voice_id() == &"default")
	assert(is_equal_approx(request.get_speech_rate(), 1.0))

#endregion
'@

$files["packages/006_voice_hub/tests/integration/test_voice_hub_composition.gd"] = @'
class_name VoiceHubCompositionTest
extends RefCounted
## Verifies safe Voice Hub composition with disabled providers.


#region Tests

static func run() -> void:
	var service := VoiceHubService.new()
	var capture := GodotVoiceCapture.new()
	var speech_to_text := DisabledSpeechToTextProvider.new()
	var text_to_speech := DisabledTextToSpeechProvider.new()

	assert(service != null)
	assert(capture != null)
	assert(not speech_to_text.is_available())
	assert(not text_to_speech.is_available())

#endregion
'@

$files["autoload/voice_hub.gd"] = @'
extends VoiceHubService
## Global Voice Hub application service.
##
## Runtime composition must call configure() before voice operations are used.
'@

$files["docs/package-dependencies-006.md"] = @'
# Package dependency 006

```text
006_voice_hub
├── 001_foundation
├── 002_design_system
├── 003_widget_library
├── 004_animation_system
└── 005_fx_system
'@

Write-Host ""
Write-Host "HYDRA AI HOME OS" -ForegroundColor Cyan
Write-Host "Installing Package 006 - Voice Hub..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $files.GetEnumerator()) {
    Write-HydraFile `
        -RelativePath $entry.Key `
        -Content $entry.Value
}

Write-Host ""
Write-Host "Package 006 installed." -ForegroundColor Green