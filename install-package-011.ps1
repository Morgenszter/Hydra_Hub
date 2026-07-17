#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

function Write-HydraFile {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content
    )

    $destination = Join-Path $RepositoryRoot $RelativePath
    $directory = Split-Path $destination -Parent

    if (-not (Test-Path $directory)) {
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    }

    if ((Test-Path $destination) -and -not $Force) {
        Write-Host "[SKIP]  $RelativePath" -ForegroundColor Yellow
        return
    }

    [System.IO.File]::WriteAllText(
        $destination,
        $Content.TrimStart(),
        $utf8WithoutBom
    )

    Write-Host "[WRITE] $RelativePath" -ForegroundColor Green
}

function Assert-HydraRepository {
    $projectFile = Join-Path $RepositoryRoot "project.godot"

    if (-not (Test-Path $projectFile)) {
        throw "Nie znaleziono project.godot w: $RepositoryRoot"
    }
}

Assert-HydraRepository

$files = [ordered]@{}

$files["packages/011_ai_system/package.cfg"] = @'
[package]

id="011_ai_system"
name="AI System"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"004_animation_system",
	"006_voice_hub",
	"010_device_hub"
)
'@

$files["packages/011_ai_system/README.md"] = @'
# Package 011 — AI System

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
'@

$files["packages/011_ai_system/CHANGELOG.md"] = @'
# AI System changelog

## [0.1.0] - 2026-07-17

### Added

- Added AI role and execution-state definitions.
- Added immutable AI message model.
- Added completion request and response models.
- Added conversation aggregate.
- Added model-provider contract.
- Added deterministic local development provider.
- Added AI System application service.
- Added AI status widget and command console.
- Added demo scene and tests.
'@

$files["packages/011_ai_system/docs/architecture.md"] = @'
# AI System architecture

AI System separates conversational domain state from model-provider adapters.

The domain layer owns conversations, messages and execution state.

The application layer coordinates requests, context limits and event
publication.

The infrastructure layer implements local or remote providers.

The presentation layer communicates only with AI System application services.
'@

$files["packages/011_ai_system/docs/security.md"] = @'
# AI security policy

Provider credentials must never be committed to the repository.

Prompt logs must not contain secrets, authentication tokens or private device
data.

External processing is disabled by default.

Provider adapters must enforce explicit timeouts, response-size limits and
structured error handling.

Tool execution requires a separate authorization boundary and is not implicitly
enabled by conversational completion.
'@

$files["packages/011_ai_system/docs/provider-contract.md"] = @'
# AI provider contract

Every provider exposes a stable provider identifier and availability state.

A provider receives AiCompletionRequest and returns Result containing
AiCompletionResponse.

Provider implementations must remain independent from presentation classes.

Remote adapters must map transport failures to DomainError.
'@

$files["packages/011_ai_system/resources/ai_system_configuration.gd"] = @'
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
'@

$files["packages/011_ai_system/resources/default_ai_system_configuration.tres"] = @'
[gd_resource type="Resource" script_class="AiSystemConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/011_ai_system/resources/ai_system_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
provider_id = &"local_demo"
model_id = &"hydra-local-demo"
allow_external_processing = false
maximum_output_tokens = 1024
context_window_tokens = 8192
temperature = 0.2
top_p = 1.0
timeout_seconds = 60.0
system_prompt = "You are HYDRA, a secure residential AI operating system."
maximum_history_messages = 32
preserve_system_messages = true
persist_conversations = false
redact_sensitive_values = true
include_device_context = false
'@

$files["packages/011_ai_system/scripts/domain/ai_message_role.gd"] = @'
class_name AiMessageRole
extends RefCounted
## Defines stable conversational message roles.


#region Values

enum Value {
	SYSTEM,
	USER,
	ASSISTANT,
	TOOL,
}

#endregion


#region Public API

## Returns a stable lowercase role identifier.
static func to_string_name(role: Value) -> StringName:
	match role:
		Value.SYSTEM:
			return &"system"
		Value.USER:
			return &"user"
		Value.ASSISTANT:
			return &"assistant"
		Value.TOOL:
			return &"tool"
		_:
			return &"unknown"

#endregion
'@

$files["packages/011_ai_system/scripts/domain/ai_execution_state.gd"] = @'
class_name AiExecutionState
extends RefCounted
## Defines AI request lifecycle states.


#region Values

enum Value {
	IDLE,
	QUEUED,
	GENERATING,
	COMPLETED,
	CANCELLED,
	FAILED,
}

#endregion


#region Public API

## Returns a stable lowercase state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.IDLE:
			return &"idle"
		Value.QUEUED:
			return &"queued"
		Value.GENERATING:
			return &"generating"
		Value.COMPLETED:
			return &"completed"
		Value.CANCELLED:
			return &"cancelled"
		Value.FAILED:
			return &"failed"
		_:
			return &"unknown"


## Returns a presentation color for the supplied state.
static func to_color(state: Value) -> Color:
	match state:
		Value.IDLE:
			return Color("#40515b")
		Value.QUEUED:
			return Color("#d6aa48")
		Value.GENERATING:
			return Color("#32d8ff")
		Value.COMPLETED:
			return Color("#55f2a3")
		Value.CANCELLED:
			return Color("#6e8794")
		Value.FAILED:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion
'@

$files["packages/011_ai_system/scripts/domain/ai_message.gd"] = @'
class_name AiMessage
extends ValueObject
## Represents one immutable conversational message.


#region State

var _message_id: StringName
var _role: AiMessageRole.Value
var _content: String
var _created_at_unix_ms: int
var _metadata: Dictionary[StringName, Variant]

#endregion


#region Construction

## Creates an immutable conversational message.
func _init(
	role: AiMessageRole.Value,
	content: String,
	metadata: Dictionary[StringName, Variant] = {}
) -> void:
	assert(
		not content.strip_edges().is_empty(),
		"AiMessage requires non-empty content."
	)

	_message_id = StringName(UUID.v4())
	_role = role
	_content = content.strip_edges()
	_created_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)
	_metadata = metadata.duplicate(true)

#endregion


#region Public API

func get_message_id() -> StringName:
	return _message_id


func get_role() -> AiMessageRole.Value:
	return _role


func get_content() -> String:
	return _content


func get_created_at_unix_ms() -> int:
	return _created_at_unix_ms


func get_metadata() -> Dictionary[StringName, Variant]:
	return _metadata.duplicate(true)


func get_metadata_value(
	key: StringName,
	default_value: Variant = null
) -> Variant:
	return _metadata.get(key, default_value)


## Serializes the message to provider-neutral data.
func to_dictionary() -> Dictionary[StringName, Variant]:
	return {
		&"message_id": _message_id,
		&"role": AiMessageRole.to_string_name(_role),
		&"content": _content,
		&"created_at_unix_ms": _created_at_unix_ms,
		&"metadata": _metadata.duplicate(true),
	}

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_message_id,
		_role,
		_content,
		_created_at_unix_ms,
		_metadata,
	]

#endregion
'@

$files["packages/011_ai_system/scripts/domain/ai_completion_request.gd"] = @'
class_name AiCompletionRequest
extends RefCounted
## Represents an immutable provider-neutral completion request.


#region State

var _request_id: StringName
var _conversation_id: StringName
var _model_id: StringName
var _messages: Array[AiMessage]
var _maximum_output_tokens: int
var _temperature: float
var _top_p: float
var _correlation_id: StringName

#endregion


#region Construction

## Creates a completion request.
func _init(
	conversation_id: StringName,
	model_id: StringName,
	messages: Array[AiMessage],
	maximum_output_tokens: int,
	temperature: float,
	top_p: float,
	correlation_id: StringName = &""
) -> void:
	assert(
		not conversation_id.is_empty(),
		"AiCompletionRequest requires conversation_id."
	)
	assert(
		not model_id.is_empty(),
		"AiCompletionRequest requires model_id."
	)
	assert(
		not messages.is_empty(),
		"AiCompletionRequest requires messages."
	)
	assert(
		maximum_output_tokens > 0,
		"AiCompletionRequest requires a positive output-token limit."
	)
	assert(
		temperature >= 0.0 and temperature <= 2.0,
		"AiCompletionRequest temperature must be between zero and two."
	)
	assert(
		top_p >= 0.0 and top_p <= 1.0,
		"AiCompletionRequest top_p must be between zero and one."
	)

	_request_id = StringName(UUID.v4())
	_conversation_id = conversation_id
	_model_id = model_id
	_messages = messages.duplicate()
	_maximum_output_tokens = maximum_output_tokens
	_temperature = temperature
	_top_p = top_p
	_correlation_id = correlation_id

	if _correlation_id.is_empty():
		_correlation_id = _request_id

#endregion


#region Public API

func get_request_id() -> StringName:
	return _request_id


func get_conversation_id() -> StringName:
	return _conversation_id


func get_model_id() -> StringName:
	return _model_id


func get_messages() -> Array[AiMessage]:
	return _messages.duplicate()


func get_maximum_output_tokens() -> int:
	return _maximum_output_tokens


func get_temperature() -> float:
	return _temperature


func get_top_p() -> float:
	return _top_p


func get_correlation_id() -> StringName:
	return _correlation_id

#endregion
'@

$files["packages/011_ai_system/scripts/domain/ai_completion_response.gd"] = @'
class_name AiCompletionResponse
extends RefCounted
## Represents an immutable AI provider response.


#region State

var _response_id: StringName
var _request_id: StringName
var _provider_id: StringName
var _model_id: StringName
var _message: AiMessage
var _input_tokens: int
var _output_tokens: int
var _completed_at_unix_ms: int
var _finish_reason: StringName

#endregion


#region Construction

## Creates an AI completion response.
func _init(
	request_id: StringName,
	provider_id: StringName,
	model_id: StringName,
	message: AiMessage,
	input_tokens: int,
	output_tokens: int,
	finish_reason: StringName
) -> void:
	assert(
		not request_id.is_empty(),
		"AiCompletionResponse requires request_id."
	)
	assert(
		not provider_id.is_empty(),
		"AiCompletionResponse requires provider_id."
	)
	assert(
		not model_id.is_empty(),
		"AiCompletionResponse requires model_id."
	)
	assert(
		message != null,
		"AiCompletionResponse requires message."
	)
	assert(
		input_tokens >= 0 and output_tokens >= 0,
		"AI token counts cannot be negative."
	)

	_response_id = StringName(UUID.v4())
	_request_id = request_id
	_provider_id = provider_id
	_model_id = model_id
	_message = message
	_input_tokens = input_tokens
	_output_tokens = output_tokens
	_completed_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)
	_finish_reason = finish_reason

#endregion


#region Public API

func get_response_id() -> StringName:
	return _response_id


func get_request_id() -> StringName:
	return _request_id


func get_provider_id() -> StringName:
	return _provider_id


func get_model_id() -> StringName:
	return _model_id


func get_message() -> AiMessage:
	return _message


func get_input_tokens() -> int:
	return _input_tokens


func get_output_tokens() -> int:
	return _output_tokens


func get_total_tokens() -> int:
	return _input_tokens + _output_tokens


func get_completed_at_unix_ms() -> int:
	return _completed_at_unix_ms


func get_finish_reason() -> StringName:
	return _finish_reason

#endregion
'@

$files["packages/011_ai_system/scripts/domain/ai_conversation.gd"] = @'
class_name AiConversation
extends AggregateRoot
## Owns one conversational context and its execution lifecycle.


#region Events

const EVENT_MESSAGE_ADDED: StringName = \
	&"hydra.ai.conversation.message_added"
const EVENT_STATE_CHANGED: StringName = \
	&"hydra.ai.conversation.state_changed"
const EVENT_COMPLETION_RECEIVED: StringName = \
	&"hydra.ai.conversation.completion_received"
const EVENT_EXECUTION_FAILED: StringName = \
	&"hydra.ai.conversation.execution_failed"

#endregion


#region State

var _title: String
var _messages: Array[AiMessage] = []
var _execution_state: AiExecutionState.Value = \
	AiExecutionState.Value.IDLE
var _last_error: DomainError
var _total_input_tokens: int = 0
var _total_output_tokens: int = 0

#endregion


#region Construction

## Creates an empty AI conversation.
func _init(
	id: EntityId,
	title: String = "NEW CONVERSATION"
) -> void:
	super(id)

	_title = title.strip_edges()

	if _title.is_empty():
		_title = "NEW CONVERSATION"

#endregion


#region Public API

func get_title() -> String:
	return _title


func get_messages() -> Array[AiMessage]:
	return _messages.duplicate()


func get_execution_state() -> AiExecutionState.Value:
	return _execution_state


func get_last_error() -> DomainError:
	return _last_error


func get_total_input_tokens() -> int:
	return _total_input_tokens


func get_total_output_tokens() -> int:
	return _total_output_tokens


## Adds a message to the conversation.
func add_message(message: AiMessage) -> Result:
	if message == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI conversation message cannot be null."
			)
		)

	_messages.append(message)
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_MESSAGE_ADDED,
			{
				&"conversation_id": get_id().as_string(),
				&"message_id": message.get_message_id(),
				&"role": AiMessageRole.to_string_name(
					message.get_role()
				),
			}
		)
	)

	return Result.success(message)


## Marks the conversation as queued.
func queue_execution() -> Result:
	return _transition(
		AiExecutionState.Value.QUEUED,
		[
			AiExecutionState.Value.IDLE,
			AiExecutionState.Value.COMPLETED,
			AiExecutionState.Value.CANCELLED,
			AiExecutionState.Value.FAILED,
		]
	)


## Marks generation as active.
func start_generation() -> Result:
	return _transition(
		AiExecutionState.Value.GENERATING,
		[AiExecutionState.Value.QUEUED]
	)


## Applies a successful provider response.
func complete(
	response: AiCompletionResponse
) -> Result:
	if response == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI completion response cannot be null."
			)
		)

	if _execution_state != AiExecutionState.Value.GENERATING:
		return _invalid_transition(
			AiExecutionState.Value.COMPLETED
		)

	var message_result := add_message(response.get_message())

	if message_result.is_failure():
		return message_result

	_total_input_tokens += response.get_input_tokens()
	_total_output_tokens += response.get_output_tokens()
	_last_error = null
	_execution_state = AiExecutionState.Value.COMPLETED
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_COMPLETION_RECEIVED,
			{
				&"conversation_id": get_id().as_string(),
				&"response_id": response.get_response_id(),
				&"provider_id": response.get_provider_id(),
				&"model_id": response.get_model_id(),
				&"input_tokens": response.get_input_tokens(),
				&"output_tokens": response.get_output_tokens(),
				&"finish_reason": response.get_finish_reason(),
			}
		)
	)

	_record_state_event()

	return Result.success(response)


## Cancels the current request.
func cancel() -> Result:
	if _execution_state == AiExecutionState.Value.CANCELLED:
		return Result.success()

	_execution_state = AiExecutionState.Value.CANCELLED
	increment_version()
	_record_state_event()

	return Result.success()


## Records a structured execution failure.
func fail(error: DomainError) -> Result:
	if error == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI execution failure cannot be null."
			)
		)

	_last_error = error
	_execution_state = AiExecutionState.Value.FAILED
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_EXECUTION_FAILED,
			{
				&"conversation_id": get_id().as_string(),
				&"error": error.to_dictionary(),
			}
		)
	)

	_record_state_event()

	return Result.success()

#endregion


#region Private methods

func _transition(
	next_state: AiExecutionState.Value,
	allowed_states: Array[AiExecutionState.Value]
) -> Result:
	if _execution_state not in allowed_states:
		return _invalid_transition(next_state)

	_execution_state = next_state
	increment_version()
	_record_state_event()

	return Result.success()


func _invalid_transition(
	next_state: AiExecutionState.Value
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"AI conversation state transition is invalid.",
			{
				&"current_state":
					AiExecutionState.to_string_name(
						_execution_state
					),
				&"requested_state":
					AiExecutionState.to_string_name(
						next_state
					),
			}
		)
	)


func _record_state_event() -> void:
	_record_domain_event(
		DomainEvent.new(
			EVENT_STATE_CHANGED,
			{
				&"conversation_id": get_id().as_string(),
				&"state": AiExecutionState.to_string_name(
					_execution_state
				),
			}
		)
	)

#endregion
'@

$files["packages/011_ai_system/scripts/contracts/ai_model_provider_port.gd"] = @'
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
'@

$files["packages/011_ai_system/scripts/infrastructure/local_demo_ai_provider.gd"] = @'
class_name LocalDemoAiProvider
extends AiModelProviderPort
## Deterministic local provider used for development and offline demos.
##
## This provider does not transmit data and does not execute external tools.


#region Constants

const PROVIDER_ID: StringName = &"local_demo"
const MODEL_ID: StringName = &"hydra-local-demo"

#endregion


#region State

var _cancelled_requests: Dictionary[StringName, bool] = {}

#endregion


#region AiModelProviderPort

func get_provider_id() -> StringName:
	return PROVIDER_ID


func is_available() -> bool:
	return true


func uses_external_processing() -> bool:
	return false


func complete(
	request: AiCompletionRequest
) -> Result:
	if request == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI completion request cannot be null."
			)
		)

	if _cancelled_requests.get(request.get_request_id(), false):
		_cancelled_requests.erase(request.get_request_id())

		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"AI completion request was cancelled.",
				{&"request_id": request.get_request_id()}
			)
		)

	var latest_user_message := _find_latest_user_message(
		request.get_messages()
	)

	if latest_user_message == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI completion request has no user message."
			)
		)

	var response_text := _build_response(
		latest_user_message.get_content()
	)
	var response_message := AiMessage.new(
		AiMessageRole.Value.ASSISTANT,
		response_text,
		{
			&"provider_id": PROVIDER_ID,
			&"model_id": MODEL_ID,
			&"local": true,
		}
	)

	var input_tokens := _estimate_tokens(
		latest_user_message.get_content()
	)
	var output_tokens := _estimate_tokens(response_text)

	return Result.success(
		AiCompletionResponse.new(
			request.get_request_id(),
			PROVIDER_ID,
			request.get_model_id(),
			response_message,
			input_tokens,
			output_tokens,
			&"stop"
		)
	)


func cancel(request_id: StringName) -> void:
	if request_id.is_empty():
		return

	_cancelled_requests[request_id] = true

#endregion


#region Private methods

func _find_latest_user_message(
	messages: Array[AiMessage]
) -> AiMessage:
	for index in range(messages.size() - 1, -1, -1):
		var message := messages[index]

		if message.get_role() == AiMessageRole.Value.USER:
			return message

	return null


func _build_response(user_text: String) -> String:
	return (
		"HYDRA LOCAL AI LINK ACTIVE.\n\n"
		+ "REQUEST RECEIVED: %s\n\n"
		+ "External model processing is disabled. "
		+ "The local development provider confirms that the "
		+ "AI System pipeline is operational."
	) % user_text


func _estimate_tokens(text: String) -> int:
	return maxi(1, int(ceil(float(text.length()) / 4.0)))

#endregion
'@

$files["packages/011_ai_system/scripts/application/ai_system_service.gd"] = @'
class_name AiSystemService
extends Node
## Coordinates AI conversations and provider execution.


#region Signals

signal conversation_created(conversation: AiConversation)
signal message_added(
	conversation: AiConversation,
	message: AiMessage
)
signal execution_state_changed(
	conversation: AiConversation,
	state: AiExecutionState.Value
)
signal completion_received(
	conversation: AiConversation,
	response: AiCompletionResponse
)
signal execution_failed(
	conversation: AiConversation,
	error: DomainError
)

#endregion


#region State

var _configuration: AiSystemConfiguration
var _providers: Dictionary[StringName, AiModelProviderPort] = {}
var _conversations: Dictionary[StringName, AiConversation] = {}
var _active_conversation_id: StringName = &""
var _active_request_id: StringName = &""

#endregion


#region Public API

## Configures AI System.
func configure(
	configuration: AiSystemConfiguration
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI System configuration cannot be null."
			)
		)

	if configuration.provider_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"AI System configuration requires provider_id."
			)
		)

	if configuration.model_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"AI System configuration requires model_id."
			)
		)

	_configuration = configuration

	return Result.success()


## Registers an AI model provider.
func register_provider(
	provider: AiModelProviderPort
) -> Result:
	if provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI model provider cannot be null."
			)
		)

	var provider_id := provider.get_provider_id()

	if provider_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"AI model provider requires provider_id."
			)
		)

	if _providers.has(provider_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_ALREADY_REGISTERED,
				"AI model provider is already registered.",
				{&"provider_id": provider_id}
			)
		)

	_providers[provider_id] = provider

	return Result.success()


## Creates and activates a conversation.
func create_conversation(
	title: String = "NEW CONVERSATION"
) -> Result:
	if _configuration == null:
		return _not_configured()

	var conversation := AiConversation.new(
		EntityId.generate(),
		title
	)
	var conversation_id := conversation.get_id().get_value()

	_conversations[conversation_id] = conversation
	_active_conversation_id = conversation_id

	if not _configuration.system_prompt.strip_edges().is_empty():
		var system_message := AiMessage.new(
			AiMessageRole.Value.SYSTEM,
			_configuration.system_prompt
		)
		conversation.add_message(system_message)
		message_added.emit(conversation, system_message)

	_publish_events(conversation)
	conversation_created.emit(conversation)

	return Result.success(conversation)


## Sends a user message through the configured provider.
func send_message(
	content: String
) -> Result:
	if _configuration == null:
		return _not_configured()

	if content.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"AI user message cannot be empty."
			)
		)

	var provider := _providers.get(
		_configuration.provider_id
	) as AiModelProviderPort

	if provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_NOT_FOUND,
				"Configured AI provider is not registered.",
				{&"provider_id": _configuration.provider_id}
			)
		)

	if not provider.is_available():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Configured AI provider is unavailable.",
				{&"provider_id": provider.get_provider_id()}
			)
		)

	if (
		provider.uses_external_processing()
		and not _configuration.allow_external_processing
	):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"External AI processing is disabled.",
				{&"provider_id": provider.get_provider_id()}
			)
		)

	var conversation := get_active_conversation()

	if conversation == null:
		var creation_result := create_conversation()

		if creation_result.is_failure():
			return creation_result

		conversation = creation_result.get_value()

	var user_message := AiMessage.new(
		AiMessageRole.Value.USER,
		content
	)
	var message_result := conversation.add_message(user_message)

	if message_result.is_failure():
		return message_result

	message_added.emit(conversation, user_message)

	var queue_result := conversation.queue_execution()

	if queue_result.is_failure():
		return queue_result

	_emit_state(conversation)

	var request_messages := _build_context_messages(conversation)
	var request := AiCompletionRequest.new(
		conversation.get_id().get_value(),
		_configuration.model_id,
		request_messages,
		_configuration.maximum_output_tokens,
		_configuration.temperature,
		_configuration.top_p
	)

	_active_request_id = request.get_request_id()

	var generation_result := conversation.start_generation()

	if generation_result.is_failure():
		return generation_result

	_emit_state(conversation)
	_publish_events(conversation)

	var completion_result := provider.complete(request)
	_active_request_id = &""

	if completion_result.is_failure():
		var error := completion_result.get_error()
		conversation.fail(error)
		_publish_events(conversation)
		_emit_state(conversation)
		execution_failed.emit(conversation, error)

		return completion_result

	var response := (
		completion_result.get_value()
		as AiCompletionResponse
	)

	var conversation_result := conversation.complete(response)

	if conversation_result.is_failure():
		return conversation_result

	_publish_events(conversation)
	_emit_state(conversation)
	message_added.emit(
		conversation,
		response.get_message()
	)
	completion_received.emit(conversation, response)

	return Result.success(response)


## Cancels the active request.
func cancel_active_request() -> Result:
	var conversation := get_active_conversation()

	if conversation == null:
		return Result.success()

	if not _active_request_id.is_empty():
		var provider := _providers.get(
			_configuration.provider_id
		) as AiModelProviderPort

		if provider != null:
			provider.cancel(_active_request_id)

	_active_request_id = &""
	conversation.cancel()
	_publish_events(conversation)
	_emit_state(conversation)

	return Result.success()


## Returns the active conversation.
func get_active_conversation() -> AiConversation:
	if _active_conversation_id.is_empty():
		return null

	return _conversations.get(_active_conversation_id)


## Returns all conversations.
func get_conversations() -> Array[AiConversation]:
	var result: Array[AiConversation] = []

	for conversation: AiConversation in _conversations.values():
		result.append(conversation)

	return result

#endregion


#region Private methods

func _build_context_messages(
	conversation: AiConversation
) -> Array[AiMessage]:
	var messages := conversation.get_messages()
	var maximum_messages := _configuration.maximum_history_messages

	if messages.size() <= maximum_messages:
		return messages

	var result: Array[AiMessage] = []

	if _configuration.preserve_system_messages:
		for message in messages:
			if message.get_role() == AiMessageRole.Value.SYSTEM:
				result.append(message)

	var start_index := maxi(
		0,
		messages.size() - maximum_messages
	)

	for index in range(start_index, messages.size()):
		var message := messages[index]

		if message not in result:
			result.append(message)

	return result


func _emit_state(
	conversation: AiConversation
) -> void:
	execution_state_changed.emit(
		conversation,
		conversation.get_execution_state()
	)


func _publish_events(
	conversation: AiConversation
) -> void:
	var events := conversation.pull_domain_events()
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"AI System is not configured."
		)
	)

#endregion
'@

$files["packages/011_ai_system/scripts/presentation/ai_status_widget.gd"] = @'
class_name AiStatusWidget
extends WidgetBase
## Displays AI provider and execution status.


#region Nodes

@onready var _indicator: ColorRect = %Indicator
@onready var _state_label: RichTextLabel = %StateLabel
@onready var _provider_label: RichTextLabel = %ProviderLabel
@onready var _token_label: RichTextLabel = %TokenLabel

#endregion


#region State

var _state: AiExecutionState.Value = AiExecutionState.Value.IDLE
var _provider_id: StringName = &"unknown"
var _model_id: StringName = &"unknown"
var _input_tokens: int = 0
var _output_tokens: int = 0

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	_refresh()

#endregion


#region Public API

func set_provider(
	provider_id: StringName,
	model_id: StringName
) -> void:
	_provider_id = provider_id
	_model_id = model_id
	_refresh()


func set_execution_state(
	state: AiExecutionState.Value
) -> void:
	_state = state
	_refresh()


func set_token_usage(
	input_tokens: int,
	output_tokens: int
) -> void:
	_input_tokens = maxi(0, input_tokens)
	_output_tokens = maxi(0, output_tokens)
	_refresh()

#endregion


#region Private methods

func _refresh() -> void:
	if not is_node_ready():
		return

	_indicator.color = AiExecutionState.to_color(_state)
	_state_label.text = (
		"AI LINK  //  %s"
		% String(
			AiExecutionState.to_string_name(_state)
		).to_upper()
	)
	_provider_label.text = (
		"PROVIDER  //  %s    MODEL  //  %s"
		% [
			String(_provider_id).to_upper(),
			String(_model_id).to_upper(),
		]
	)
	_token_label.text = (
		"TOKENS  //  IN %d    OUT %d    TOTAL %d"
		% [
			_input_tokens,
			_output_tokens,
			_input_tokens + _output_tokens,
		]
	)

#endregion
'@

$files["packages/011_ai_system/scripts/presentation/ai_console_panel.gd"] = @'
class_name AiConsolePanel
extends PanelBase
## Conversational AI command-console panel.


#region Nodes

@onready var _status_widget: AiStatusWidget = %AiStatusWidget
@onready var _conversation_output: RichTextLabel = %ConversationOutput
@onready var _prompt_input: LineEdit = %PromptInput
@onready var _send_button: HydraButton = %SendButton
@onready var _cancel_button: HydraButton = %CancelButton
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: AiSystemService
var _configuration: AiSystemConfiguration

#endregion


#region Lifecycle

func _ready() -> void:
	super()

	_send_button.pressed.connect(_on_send_button_pressed)
	_cancel_button.pressed.connect(_on_cancel_button_pressed)
	_prompt_input.text_submitted.connect(_on_prompt_submitted)

#endregion


#region Public API

## Binds the panel to AI System.
func bind_service(
	service: AiSystemService,
	configuration: AiSystemConfiguration
) -> void:
	assert(service != null, "AI System service cannot be null.")
	assert(
		configuration != null,
		"AI System configuration cannot be null."
	)

	_disconnect_service()
	_service = service
	_configuration = configuration

	_service.conversation_created.connect(
		_on_conversation_created
	)
	_service.message_added.connect(_on_message_added)
	_service.execution_state_changed.connect(
		_on_execution_state_changed
	)
	_service.completion_received.connect(
		_on_completion_received
	)
	_service.execution_failed.connect(
		_on_execution_failed
	)

	_status_widget.set_provider(
		configuration.provider_id,
		configuration.model_id
	)


## Clears visible conversation output.
func clear_output() -> void:
	_conversation_output.text = ""

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.conversation_created.is_connected(
		_on_conversation_created
	):
		_service.conversation_created.disconnect(
			_on_conversation_created
		)

	if _service.message_added.is_connected(_on_message_added):
		_service.message_added.disconnect(_on_message_added)

	if _service.execution_state_changed.is_connected(
		_on_execution_state_changed
	):
		_service.execution_state_changed.disconnect(
			_on_execution_state_changed
		)

	if _service.completion_received.is_connected(
		_on_completion_received
	):
		_service.completion_received.disconnect(
			_on_completion_received
		)

	if _service.execution_failed.is_connected(
		_on_execution_failed
	):
		_service.execution_failed.disconnect(
			_on_execution_failed
		)


func _submit_prompt(text: String) -> void:
	if _service == null:
		return

	var normalized_text := text.strip_edges()

	if normalized_text.is_empty():
		return

	_error_label.visible = false
	_prompt_input.clear()

	var result := _service.send_message(normalized_text)

	if result.is_failure():
		_on_execution_failed(
			_service.get_active_conversation(),
			result.get_error()
		)


func _append_message(message: AiMessage) -> void:
	var role := String(
		AiMessageRole.to_string_name(
			message.get_role()
		)
	).to_upper()

	var color := "#d6aa48"

	match message.get_role():
		AiMessageRole.Value.SYSTEM:
			color = "#6e8794"
		AiMessageRole.Value.USER:
			color = "#d6aa48"
		AiMessageRole.Value.ASSISTANT:
			color = "#32d8ff"
		AiMessageRole.Value.TOOL:
			color = "#55f2a3"

	_conversation_output.append_text(
		"[color=%s]%s[/color]\n%s\n\n"
		% [
			color,
			role,
			_escape_bbcode(message.get_content()),
		]
	)

	_conversation_output.scroll_to_line(
		_conversation_output.get_line_count()
	)


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")


func _on_send_button_pressed(
	_action_id: StringName
) -> void:
	_submit_prompt(_prompt_input.text)


func _on_cancel_button_pressed(
	_action_id: StringName
) -> void:
	if _service != null:
		_service.cancel_active_request()


func _on_prompt_submitted(text: String) -> void:
	_submit_prompt(text)


func _on_conversation_created(
	conversation: AiConversation
) -> void:
	_conversation_output.text = (
		"[color=#6e8794]CONVERSATION  //  %s[/color]\n\n"
		% conversation.get_title()
	)


func _on_message_added(
	_conversation: AiConversation,
	message: AiMessage
) -> void:
	_append_message(message)


func _on_execution_state_changed(
	_conversation: AiConversation,
	state: AiExecutionState.Value
) -> void:
	_status_widget.set_execution_state(state)


func _on_completion_received(
	conversation: AiConversation,
	_response: AiCompletionResponse
) -> void:
	_status_widget.set_token_usage(
		conversation.get_total_input_tokens(),
		conversation.get_total_output_tokens()
	)


func _on_execution_failed(
	_conversation: AiConversation,
	error: DomainError
) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]AI EXECUTION FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % _escape_bbcode(error.get_message())

#endregion
'@

$files["packages/011_ai_system/scenes/ai_status_widget.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/011_ai_system/scripts/presentation/ai_status_widget.gd" id="1"]

[node name="AiStatusWidget" type="Control"]
custom_minimum_size = Vector2(880, 112)
layout_mode = 3
anchors_preset = 0
offset_right = 880.0
offset_bottom = 112.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"ai_status_widget"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.027451, 0.0901961, 0.133333, 0.92)

[node name="Indicator" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 18.0
offset_top = 16.0
offset_right = 26.0
offset_bottom = 96.0
mouse_filter = 2
color = Color(0.25098, 0.317647, 0.356863, 1)

[node name="StateLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 46.0
offset_top = 12.0
offset_right = 840.0
offset_bottom = 40.0
bbcode_enabled = true
text = "[color=#32d8ff]AI LINK  //  IDLE[/color]"
fit_content = true
scroll_active = false

[node name="ProviderLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 46.0
offset_top = 44.0
offset_right = 840.0
offset_bottom = 72.0
text = "PROVIDER  //  UNKNOWN    MODEL  //  UNKNOWN"
fit_content = true
scroll_active = false

[node name="TokenLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 46.0
offset_top = 76.0
offset_right = 840.0
offset_bottom = 104.0
text = "TOKENS  //  IN 0    OUT 0    TOTAL 0"
fit_content = true
scroll_active = false
'@

$files["packages/011_ai_system/scenes/ai_console_panel.tscn"] = @'
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://packages/011_ai_system/scripts/presentation/ai_console_panel.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/011_ai_system/scenes/ai_status_widget.tscn" id="2"]
[ext_resource type="PackedScene" path="res://packages/003_widget_library/scenes/hydra_button.tscn" id="3"]

[node name="AiConsolePanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 1020.0
offset_bottom = 900.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"ai_console_panel"
starts_open = true

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.0117647, 0.0313725, 0.0509804, 0.97)

[node name="HeaderAccent" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 28.0
offset_top = 24.0
offset_right = 34.0
offset_bottom = 94.0
mouse_filter = 2
color = Color(0.839216, 0.666667, 0.282353, 1)

[node name="Title" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 20.0
offset_right = 700.0
offset_bottom = 60.0
bbcode_enabled = true
text = "[font_size=30][color=#32d8ff]AI SYSTEM[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 62.0
offset_right = 900.0
offset_bottom = 96.0
bbcode_enabled = true
text = "[color=#6e8794]COGNITIVE COMMAND INTERFACE  //  CHANNEL 011[/color]"
fit_content = true
scroll_active = false

[node name="AiStatusWidget" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 116.0
offset_right = 934.0
offset_bottom = 228.0

[node name="OutputFrame" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 252.0
offset_right = 966.0
offset_bottom = 682.0
mouse_filter = 2
color = Color(0.027451, 0.0901961, 0.133333, 0.76)

[node name="ConversationOutput" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 76.0
offset_top = 274.0
offset_right = 944.0
offset_bottom = 660.0
bbcode_enabled = true
text = "[color=#40515b]AI CONSOLE READY[/color]"
scroll_active = true
selection_enabled = true

[node name="PromptInput" type="LineEdit" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 716.0
offset_right = 966.0
offset_bottom = 770.0
placeholder_text = "ENTER COMMAND OR QUESTION..."
clear_button_enabled = true

[node name="SendButton" parent="." instance=ExtResource("3")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 798.0
offset_right = 310.0
offset_bottom = 862.0
action_id = &"ai_send"
text = "EXECUTE"

[node name="CancelButton" parent="." instance=ExtResource("3")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 338.0
offset_top = 798.0
offset_right = 594.0
offset_bottom = 862.0
action_id = &"ai_cancel"
text = "CANCEL"
accent_color = Color(1, 0.309804, 0.384314, 1)

[node name="ErrorLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
visible = false
layout_mode = 0
offset_left = 622.0
offset_top = 798.0
offset_right = 966.0
offset_bottom = 876.0
bbcode_enabled = true
text = "[color=#ff4f62]AI EXECUTION FAILURE[/color]"
scroll_active = false
'@

$files["packages/011_ai_system/demo/ai_system_demo.gd"] = @'
class_name AiSystemDemo
extends Control
## Demonstrates AI System with the local development provider.


#region Nodes

@onready var _panel: AiConsolePanel = %AiConsolePanel

#endregion


#region State

var _service: AiSystemService
var _configuration: AiSystemConfiguration

#endregion


#region Lifecycle

func _ready() -> void:
	_service = AiSystemService.new()
	_service.name = "AiSystemService"
	add_child(_service)

	_configuration = AiSystemConfiguration.new()

	var configuration_result := _service.configure(
		_configuration
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	var provider := LocalDemoAiProvider.new()
	var provider_result := _service.register_provider(provider)

	if provider_result.is_failure():
		push_error(
			provider_result.get_error().get_message()
		)
		return

	_panel.bind_service(
		_service,
		_configuration
	)

	_service.create_conversation(
		"HYDRA LOCAL SESSION"
	)

#endregion
'@

$files["packages/011_ai_system/demo/ai_system_demo.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/011_ai_system/demo/ai_system_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/011_ai_system/scenes/ai_console_panel.tscn" id="2"]

[node name="AiSystemDemo" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.00392157, 0.0117647, 0.0196078, 1)

[node name="AiConsolePanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 450.0
offset_top = 90.0
offset_right = 1470.0
offset_bottom = 990.0
'@

$files["packages/011_ai_system/tests/unit/test_ai_message.gd"] = @'
class_name AiMessageTest
extends RefCounted
## Provides AiMessage value-object tests.


#region Tests

static func run() -> void:
	var message := AiMessage.new(
		AiMessageRole.Value.USER,
		"System status."
	)

	assert(not message.get_message_id().is_empty())
	assert(message.get_role() == AiMessageRole.Value.USER)
	assert(message.get_content() == "System status.")
	assert(message.to_dictionary()[&"role"] == &"user")

#endregion
'@

$files["packages/011_ai_system/tests/unit/test_ai_conversation.gd"] = @'
class_name AiConversationTest
extends RefCounted
## Provides AiConversation aggregate tests.


#region Tests

static func run() -> void:
	var conversation := AiConversation.new(
		EntityId.generate(),
		"TEST CONVERSATION"
	)
	var message := AiMessage.new(
		AiMessageRole.Value.USER,
		"Test request."
	)

	assert(conversation.add_message(message).is_success())
	assert(conversation.get_messages().size() == 1)
	assert(conversation.queue_execution().is_success())
	assert(conversation.start_generation().is_success())
	assert(
		conversation.get_execution_state()
		== AiExecutionState.Value.GENERATING
	)
	assert(not conversation.pull_domain_events().is_empty())

#endregion
'@

$files["packages/011_ai_system/tests/unit/test_local_demo_ai_provider.gd"] = @'
class_name LocalDemoAiProviderTest
extends RefCounted
## Provides deterministic local-provider tests.


#region Tests

static func run() -> void:
	var provider := LocalDemoAiProvider.new()
	var messages: Array[AiMessage] = [
		AiMessage.new(
			AiMessageRole.Value.USER,
			"Report status."
		),
	]
	var request := AiCompletionRequest.new(
		&"conversation_test",
		&"hydra-local-demo",
		messages,
		256,
		0.2,
		1.0
	)

	var result := provider.complete(request)

	assert(result.is_success())

	var response := result.get_value() as AiCompletionResponse

	assert(response != null)
	assert(response.get_provider_id() == &"local_demo")
	assert(
		response.get_message().get_role()
		== AiMessageRole.Value.ASSISTANT
	)
	assert(response.get_total_tokens() > 0)

#endregion
'@

$files["packages/011_ai_system/tests/integration/test_ai_system_service.gd"] = @'
class_name AiSystemServiceTest
extends RefCounted
## Provides AI System service composition tests.


#region Tests

static func run() -> void:
	var service := AiSystemService.new()
	var configuration := AiSystemConfiguration.new()
	var provider := LocalDemoAiProvider.new()

	assert(service.configure(configuration).is_success())
	assert(service.register_provider(provider).is_success())

	var conversation_result := service.create_conversation(
		"TEST"
	)

	assert(conversation_result.is_success())

#endregion
'@

$files["autoload/ai_system.gd"] = @'
extends AiSystemService
## Global AI System application service.
##
## Runtime composition must configure AI System and register a model provider.
'@

$files["docs/package-dependencies-011.md"] = @'
# Package dependency 011

```text
011_ai_system
├── 001_foundation
├── 002_design_system
├── 003_widget_library
├── 004_animation_system
├── 006_voice_hub
└── 010_device_hub
'@

Write-Host ""
Write-Host "HYDRA AI HOME OS" -ForegroundColor Cyan
Write-Host "Installing Package 011 - AI System..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $files.GetEnumerator()) {
Write-HydraFile -RelativePath $entry.Key -Content $entry.Value
}

Write-Host ""
Write-Host "Package 011 installed." -ForegroundColor Green
Write-Host ""
Write-Host "Optional autoload:" -ForegroundColor Cyan
Write-Host "AiSystem res://autoload/ai_system.gd"
Write-Host ""
Write-Host "Git commands:" -ForegroundColor Cyan
Write-Host "git add ."
Write-Host 'git commit -m "feat(ai-system): implement package 011"'
Write-Host "git push"