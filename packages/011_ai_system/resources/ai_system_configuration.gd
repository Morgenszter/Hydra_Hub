class_name AiSystemConfiguration
extends Resource
## Stores provider-independent AI System runtime configuration.
##
## Credentials are intentionally excluded from this resource.


#region Provider

@export_group("Provider")
@export var provider_id: StringName = &"local_demo"
@export var model_id: StringName = &"hydra-local-demo"
@export var allow_external_processing: bool = false

#endregion


#region Generation

@export_group("Generation")
@export_range(1, 32768, 1) var maximum_output_tokens: int = 1024
@export_range(128, 262144, 128) var context_window_tokens: int = 8192
@export_range(0.0, 2.0, 0.01) var temperature: float = 0.2
@export_range(0.0, 1.0, 0.01) var top_p: float = 1.0
@export_range(1.0, 300.0, 1.0) var timeout_seconds: float = 60.0

#endregion


#region Context

@export_group("Context")
@export var system_prompt: String = \
	"You are HYDRA, a secure residential AI operating system."
@export_range(1, 256, 1) var maximum_history_messages: int = 32
@export var preserve_system_messages: bool = true

#endregion


#region Privacy

@export_group("Privacy")
@export var persist_conversations: bool = false
@export var redact_sensitive_values: bool = true
@export var include_device_context: bool = false

#endregion