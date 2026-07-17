class_name BootProgressPanel
extends PanelBase
## Displays HYDRA startup progress.


#region Nodes

@onready var _state_label: RichTextLabel = %StateLabel
@onready var _step_label: RichTextLabel = %StepLabel
@onready var _progress_fill: ColorRect = %ProgressFill
@onready var _progress_label: RichTextLabel = %ProgressLabel
@onready var _log_output: RichTextLabel = %LogOutput
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: BootLoaderService

#endregion


#region Public API

## Binds this panel to BootLoaderService.
func bind_service(service: BootLoaderService) -> void:
	assert(service != null, "Boot Loader service cannot be null.")

	_disconnect_service()
	_service = service

	_service.boot_started.connect(_on_boot_started)
	_service.step_started.connect(_on_step_started)
	_service.step_completed.connect(_on_step_completed)
	_service.step_failed.connect(_on_step_failed)
	_service.boot_completed.connect(_on_boot_completed)
	_service.boot_failed.connect(_on_boot_failed)
	_service.scene_transition_started.connect(
		_on_scene_transition_started
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.boot_started.is_connected(_on_boot_started):
		_service.boot_started.disconnect(_on_boot_started)

	if _service.step_started.is_connected(_on_step_started):
		_service.step_started.disconnect(_on_step_started)

	if _service.step_completed.is_connected(_on_step_completed):
		_service.step_completed.disconnect(_on_step_completed)

	if _service.step_failed.is_connected(_on_step_failed):
		_service.step_failed.disconnect(_on_step_failed)

	if _service.boot_completed.is_connected(_on_boot_completed):
		_service.boot_completed.disconnect(_on_boot_completed)

	if _service.boot_failed.is_connected(_on_boot_failed):
		_service.boot_failed.disconnect(_on_boot_failed)

	if _service.scene_transition_started.is_connected(
		_on_scene_transition_started
	):
		_service.scene_transition_started.disconnect(
			_on_scene_transition_started
		)


func _on_boot_started(
	_sequence: BootSequence
) -> void:
	_error_label.visible = false
	_log_output.text = ""
	_state_label.text = "STATE  //  BOOTING"
	_set_progress(0.0)
	_append_log("BOOT SEQUENCE INITIALIZED", "#32d8ff")


func _on_step_started(
	step: BootStep,
	index: int,
	total: int
) -> void:
	_step_label.text = (
		"STEP %d / %d  //  %s"
		% [
			index + 1,
			total,
			step.get_display_name(),
		]
	)
	_append_log(
		"START  //  %s" % step.get_display_name(),
		"#d6aa48"
	)


func _on_step_completed(
	step: BootStep,
	progress: float
) -> void:
	_set_progress(progress)
	_append_log(
		"OK     //  %s" % step.get_display_name(),
		"#55f2a3"
	)


func _on_step_failed(
	step: BootStep,
	error: DomainError,
	critical: bool
) -> void:
	var severity := "CRITICAL" if critical else "OPTIONAL"
	_append_log(
		"%s  //  %s  //  %s"
		% [
			severity,
			step.get_display_name(),
			error.get_message(),
		],
		"#ff4f62"
	)


func _on_boot_completed(
	_sequence: BootSequence
) -> void:
	_state_label.text = "STATE  //  COMPLETED"
	_step_label.text = "ALL CRITICAL SYSTEMS OPERATIONAL"
	_set_progress(1.0)
	_append_log("BOOT SEQUENCE COMPLETED", "#55f2a3")


func _on_boot_failed(
	_sequence: BootSequence,
	error: DomainError
) -> void:
	_state_label.text = "STATE  //  FAILED"
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]BOOT FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()


func _on_scene_transition_started(
	scene_path: String
) -> void:
	_state_label.text = "STATE  //  TRANSITIONING"
	_append_log(
		"LOADING  //  %s" % scene_path,
		"#32d8ff"
	)


func _set_progress(progress: float) -> void:
	var normalized := clampf(progress, 0.0, 1.0)
	_progress_fill.scale.x = normalized
	_progress_label.text = "%d%%" % int(normalized * 100.0)


func _append_log(
	message: String,
	color: String
) -> void:
	_log_output.append_text(
		"[color=%s]%s[/color]\n"
		% [
			color,
			message,
		]
	)
	_log_output.scroll_to_line(
		_log_output.get_line_count()
	)

#endregion