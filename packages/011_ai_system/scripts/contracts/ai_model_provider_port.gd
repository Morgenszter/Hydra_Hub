@abstract
class_name AiModelProviderPort
extends RefCounted
## Defines a provider-independent AI model boundary.


#region Public API

## Returns the stable provider identifier.
@abstract
func get_provider_id() -> StringName


## Returns whether the provider is configured and available.
@abstract
func is_available() -> bool


## Returns whether the provider transmits data externally.
@abstract
func uses_external_processing() -> bool


## Executes a completion request.
@abstract
func complete(
	request: AiCompletionRequest
) -> Result


## Cancels the active request when supported.
@abstract
func cancel(
	request_id: StringName
) -> void

#endregion