class_name BootLoaderScreen
extends Control
## Composition root for the HYDRA boot screen.


#region Resources

@export var configuration: BootLoaderConfiguration

#endregion


#region Nodes

@onready var _panel: BootProgressPanel = %BootProgressPanel

#endregion


#region State

var _service: BootLoaderService

#endregion


#region Lifecycle

func _ready() -> void:
	if configuration == null:
		configuration = BootLoaderConfiguration.new()

	_service = BootLoaderService.new()
	_service.name = "BootLoaderService"
	add_child(_service)

	var result := _service.configure(configuration)

	if result.is_failure():
		push_error(result.get_error().get_message())
		return

	_register_default_steps()
	_panel.bind_service(_service)

	if configuration.start_automatically:
		_service.start_boot()


#region Private methods

func _register_default_steps() -> void:
	_service.register_step(
		CallableBootStep.new(
			&"validate_runtime",
			"VALIDATE RUNTIME",
			10,
			true,
			_validate_runtime
		)
	)
	_service.register_step(
		CallableBootStep.new(
			&"validate_project",
			"VALIDATE PROJECT CONFIGURATION",
			20,
			true,
			_validate_project
		)
	)
	_service.register_step(
		CallableBootStep.new(
			&"initialize_services",
			"INITIALIZE CORE SERVICES",
			30,
			true,
			_initialize_services
		)
	)
	_service.register_step(
		CallableBootStep.new(
			&"run_diagnostics",
			"RUN STARTUP DIAGNOSTICS",
			40,
			false,
			_run_diagnostics
		)
	)


func _validate_runtime() -> Result:
	if Engine.get_version_info().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Godot runtime information is unavailable."
			)
		)

	return Result.success()


func _validate_project() -> Result:
	if not ResourceLoader.exists(
		configuration.target_scene_path
	):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Configured target scene does not exist.",
				{
					&"scene_path":
						configuration.target_scene_path,
				}
			)
		)

	return Result.success()


func _initialize_services() -> Result:
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_NOT_FOUND,
				"EventBus autoload is unavailable."
			)
		)

	return Result.success()


func _run_diagnostics() -> Result:
	var diagnostics := get_node_or_null("/root/Diagnostics")

	if diagnostics == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_NOT_FOUND,
				"Diagnostics autoload is unavailable."
			)
		)

	return diagnostics.run_all()

#endregion