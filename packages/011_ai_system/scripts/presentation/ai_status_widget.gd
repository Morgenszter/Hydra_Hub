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