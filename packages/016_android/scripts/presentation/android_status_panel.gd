class_name AndroidStatusPanel
extends PanelBase
## Displays Android platform availability and capabilities.


#region Constants

const CAPABILITY_START_Y: float = 250.0
const CAPABILITY_ROW_HEIGHT: float = 38.0

#endregion


#region Nodes

@onready var _platform_label: RichTextLabel = %PlatformLabel
@onready var _model_label: RichTextLabel = %ModelLabel
@onready var _sdk_label: RichTextLabel = %SdkLabel
@onready var _capability_output: RichTextLabel = %CapabilityOutput
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: AndroidPlatformService

#endregion


#region Public API

## Binds the panel to AndroidPlatformService.
func bind_service(
	service: AndroidPlatformService
) -> void:
	assert(
		service != null,
		"Android platform service cannot be null."
	)

	_disconnect_service()
	_service = service

	_service.platform_initialized.connect(
		_on_platform_initialized
	)
	_service.platform_operation_failed.connect(
		_on_platform_operation_failed
	)

	var info := _service.get_platform_info()

	if info != null:
		_render_info(info)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.platform_initialized.is_connected(
		_on_platform_initialized
	):
		_service.platform_initialized.disconnect(
			_on_platform_initialized
		)

	if _service.platform_operation_failed.is_connected(
		_on_platform_operation_failed
	):
		_service.platform_operation_failed.disconnect(
			_on_platform_operation_failed
		)


func _on_platform_initialized(
	info: AndroidPlatformInfo
) -> void:
	_error_label.visible = false
	_render_info(info)


func _render_info(info: AndroidPlatformInfo) -> void:
	_platform_label.text = (
		"PLATFORM  //  %s"
		% info.get_operating_system_name().to_upper()
	)
	_model_label.text = (
		"MODEL  //  %s"
		% info.get_model_name().to_upper()
	)
	_sdk_label.text = (
		"ANDROID SDK  //  %d"
		% info.get_sdk_version()
	)

	_capability_output.text = ""

	for capability in AndroidCapability.get_all():
		var available := info.has_capability(capability)
		var color := "#55f2a3" if available else "#40515b"
		var state := "AVAILABLE" if available else "UNAVAILABLE"

		_capability_output.append_text(
			"[color=%s]%s  //  %s[/color]\n"
			% [
				color,
				String(capability).to_upper(),
				state,
			]
		)


func _on_platform_operation_failed(
	error: DomainError
) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]ANDROID OPERATION FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()

#endregion