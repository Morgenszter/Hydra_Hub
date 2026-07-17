# AI provider contract

Every provider exposes a stable provider identifier and availability state.

A provider receives AiCompletionRequest and returns Result containing
AiCompletionResponse.

Provider implementations must remain independent from presentation classes.

Remote adapters must map transport failures to DomainError.