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