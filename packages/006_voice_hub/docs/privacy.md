# Voice privacy

Microphone input is disabled by default.

External transmission requires an explicitly configured provider.

Secrets must be loaded from environment variables, operating-system credential
storage or an encrypted settings service.

Raw audio must not be written to disk unless recording has been explicitly
enabled by the user.

Diagnostic logs must not contain raw audio, access tokens or complete
transcriptions marked as private.