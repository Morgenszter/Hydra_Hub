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