# AI System architecture

AI System separates conversational domain state from model-provider adapters.

The domain layer owns conversations, messages and execution state.

The application layer coordinates requests, context limits and event
publication.

The infrastructure layer implements local or remote providers.

The presentation layer communicates only with AI System application services.