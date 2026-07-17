# Voice Hub architecture

Voice Hub is divided into domain, application, infrastructure and presentation
layers.

The domain layer contains provider-independent state and request models.

The application layer coordinates use cases through abstract ports.

The infrastructure layer integrates Godot audio capture and provider adapters.

The presentation layer exposes the current voice state through reusable controls.