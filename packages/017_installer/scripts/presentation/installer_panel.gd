class_name InstallerPanel
extends PanelBase
## Displays installation progress and state.


#region Nodes

@onready var _package_label: RichTextLabel = %PackageLabel
@onready var _state_label: RichTextLabel = %StateLabel
@onready var _progress_fill: ColorRect = %ProgressFill
@onready var _progress_label: RichTextLabel = %ProgressLabel
@onready var _operation_label: RichTextLabel = %OperationLabel
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: InstallerService

#endregion


#region Public API

## Binds the panel to InstallerService.
func bind_service(service: InstallerService) -> void:
	assert(service != null, "Installer service cannot be null.")

	_disconnect_service()
	_service = service

	_service.installation_started.connect(
		_on_installation_started
	)
	_service.operation_completed.connect(
		_on_operation_completed
	)
	_service.installation_progress_changed.connect(
		_on_progress_changed
	)
	_service.installation_completed.connect(
		_on_installation_completed
	)
	_service.installation_failed.connect(
		_on_installation_failed
	)
	_service.rollback_completed.connect(
		_on_rollback_completed
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.installation_started.is_connected(
		_on_installation_started
	):
		_service.installation_started.disconnect(
			_on_installation_started
		)

	if _service.operation_completed.is_connected(
		_on_operation_completed
	):
		_service.operation_completed.disconnect(
			_on_operation_completed
		)

	if _service.installation_progress_changed.is_connected(
		_on_progress_changed
	):
		_service.installation_progress_changed.disconnect(
			_on_progress_changed
		)

	if _service.installation_completed.is_connected(
		_on_installation_completed
	):
		_service.installation_completed.disconnect(
			_on_installation_completed
		)

	if _service.installation_failed.is_connected(
		_on_installation_failed
	):
		_service.installation_failed.disconnect(
			_on_installation_failed
		)

	if _service.rollback_completed.is_connected(
		_on_rollback_completed
	):
		_service.rollback_completed.disconnect(
			_on_rollback_completed
		)


func _on_installation_started(
	plan: InstallationPlan
) -> void:
	_error_label.visible = false
	_package_label.text = (
		"PACKAGE  //  %s    VERSION  //  %s"
		% [
			plan.get_manifest().display_name,
			plan.get_manifest().version,
		]
	)
	_set_state(plan)
	_set_progress(0.0)


func _on_operation_completed(
	_plan: InstallationPlan,
	operation: InstallationOperation
) -> void:
	_operation_label.text = (
		"OPERATION  //  %s"
		% operation.get_relative_path()
	)


func _on_progress_changed(
	plan: InstallationPlan,
	progress: float
) -> void:
	_set_state(plan)
	_set_progress(progress)


func _on_installation_completed(
	plan: InstallationPlan
) -> void:
	_set_state(plan)
	_set_progress(1.0)
	_operation_label.text = "INSTALLATION COMPLETED"


func _on_installation_failed(
	plan: InstallationPlan,
	error: DomainError
) -> void:
	_set_state(plan)
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]INSTALLATION FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()


func _on_rollback_completed(
	plan: InstallationPlan
) -> void:
	_set_state(plan)
	_operation_label.text = "ROLLBACK COMPLETED"


func _set_state(plan: InstallationPlan) -> void:
	_state_label.text = (
		"STATE  //  %s"
		% String(
			InstallationState.to_string_name(
				plan.get_state()
			)
		).to_upper()
	)


func _set_progress(progress: float) -> void:
	var normalized := clampf(progress, 0.0, 1.0)
	_progress_fill.scale.x = normalized
	_progress_label.text = "%d%%" % int(normalized * 100.0)

#endregion