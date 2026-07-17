class_name InstallerService
extends Node
## Validates and executes installation plans.


#region Signals

signal installation_started(plan: InstallationPlan)
signal operation_completed(
	plan: InstallationPlan,
	operation: InstallationOperation
)
signal installation_progress_changed(
	plan: InstallationPlan,
	progress: float
)
signal installation_completed(plan: InstallationPlan)
signal installation_failed(
	plan: InstallationPlan,
	error: DomainError
)
signal rollback_completed(plan: InstallationPlan)

#endregion


#region State

var _configuration: InstallerConfiguration
var _file_system: InstallerFileSystemPort
var _active_plan: InstallationPlan

#endregion


#region Public API

## Configures Installer.
func configure(
	configuration: InstallerConfiguration,
	file_system: InstallerFileSystemPort
) -> Result:
	if configuration == null or file_system == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Installer configuration and file system are required."
			)
		)

	_configuration = configuration
	_file_system = file_system

	return Result.success()


## Executes a complete installation plan.
func install(
	plan: InstallationPlan
) -> Result:
	if _configuration == null or _file_system == null:
		return _not_configured()

	if plan == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Installation plan cannot be null."
			)
		)

	var validation_result := plan.validate_plan(
		_configuration.maximum_operations
	)

	if validation_result.is_failure():
		return validation_result

	var start_result := plan.start_installation()

	if start_result.is_failure():
		return start_result

	_active_plan = plan
	installation_started.emit(plan)
	_publish_events(plan)

	for operation in plan.get_operations():
		var operation_result := _execute_operation(operation)

		if operation_result.is_failure():
			return _handle_failure(
				plan,
				operation_result.get_error()
			)

		plan.record_operation_completed(operation)
		_publish_events(plan)
		operation_completed.emit(plan, operation)
		installation_progress_changed.emit(
			plan,
			plan.get_progress()
		)

	var completion_result := plan.complete_installation()

	if completion_result.is_failure():
		return _handle_failure(
			plan,
			completion_result.get_error()
		)

	_publish_events(plan)
	installation_completed.emit(plan)
	_active_plan = null

	return Result.success(plan)


## Returns the active plan.
func get_active_plan() -> InstallationPlan:
	return _active_plan

#endregion


#region Private methods

func _execute_operation(
	operation: InstallationOperation
) -> Result:
	match operation.get_type():
		InstallationOperation.Type.CREATE_DIRECTORY:
			return _file_system.create_directory(
				operation.get_relative_path()
			)

		InstallationOperation.Type.WRITE_TEXT_FILE:
			if (
				operation.get_content().to_utf8_buffer().size()
				> _configuration.maximum_file_size_bytes
			):
				return Result.failure(
					DomainError.new(
						HydraErrors.INVALID_ARGUMENT,
						"Installation file exceeds size limit.",
						{
							&"path":
								operation.get_relative_path(),
						}
					)
				)

			return _file_system.write_text_file(
				operation.get_relative_path(),
				operation.get_content(),
				(
					_configuration.allow_overwrite
					or operation.can_replace_existing()
				)
			)

		InstallationOperation.Type.REMOVE_FILE:
			return _file_system.remove_file(
				operation.get_relative_path()
			)

		_:
			return Result.failure(
				DomainError.new(
					HydraErrors.INVALID_ARGUMENT,
					"Unsupported installation operation."
				)
			)


func _handle_failure(
	plan: InstallationPlan,
	error: DomainError
) -> Result:
	plan.fail_installation(error)
	_publish_events(plan)
	installation_failed.emit(plan, error)

	if _configuration.rollback_on_failure:
		plan.start_rollback()
		_file_system.rollback()
		plan.complete_rollback()
		_publish_events(plan)
		rollback_completed.emit(plan)

	_active_plan = null

	return Result.failure(error)


func _publish_events(plan: InstallationPlan) -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	var events := plan.pull_domain_events()

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Installer is not configured."
		)
	)

#endregion