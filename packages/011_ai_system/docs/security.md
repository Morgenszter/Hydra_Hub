# AI security policy

Provider credentials must never be committed to the repository.

Prompt logs must not contain secrets, authentication tokens or private device
data.

External processing is disabled by default.

Provider adapters must enforce explicit timeouts, response-size limits and
structured error handling.

Tool execution requires a separate authorization boundary and is not implicitly
enabled by conversational completion.