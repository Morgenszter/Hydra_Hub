# Package 011 â€” AI System

AI System owns provider-independent conversational AI contracts, conversation
state, prompt execution, model configuration and the AI command console.

The package does not store provider credentials in scripts, scenes or resources.

## Responsibilities

AI System provides:

- Conversation aggregates.
- Immutable AI messages.
- Provider-independent completion requests.
- Model-provider contracts.
- Context-window management.
- Safe local development provider.
- AI orchestration service.
- AI console presentation.

## Security

Credentials must be supplied through a secure runtime service.

Private data must not be transmitted to external providers unless the active
configuration explicitly permits external processing.