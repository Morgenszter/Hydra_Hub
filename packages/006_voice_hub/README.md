# Package 006 â€” Voice Hub

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