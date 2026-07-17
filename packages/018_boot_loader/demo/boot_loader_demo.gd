class_name BootLoaderDemo
extends Control
## Demonstrates Boot Loader without changing the current scene.


#region Nodes

@onready var _panel: BootProgressPanel = %BootProgressPanel

#endregion


#region State

var _service: BootLoaderService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = BootLoaderService.new()
	_service.name = "BootLoaderService"
	add_child(_service)

	var configuration := BootLoaderConfiguration.new()
	configuration.change_scene_after_completion = false
	configuration.minimum_step_display_seconds = 0.25

	_service.configure(configuration)
	_panel.bind_service(_service)

	_service.register_step(
		CallableBootStep.new(
			&"demo_core",
			"INITIALIZE CORE",
			10,
			true,
			func() -> Result:
				return Result.success()
		)
	)
	_service.register_step(
		CallableBootStep.new(
			&"demo_services",
			"INITIALIZE SERVICES",
			20,
			true,
			func() -> Result:
				return Result.success()
		)
	)
	_service.register_step(
		CallableBootStep.new(
			&"demo_optional",
			"CHECK OPTIONAL LINK",
			30,
			false,
			func() -> Result:
				return Result.failure(
					DomainError.new(
						HydraErrors.SERVICE_NOT_FOUND,
						"Optional demo service is offline."
					)
				)
		)
	)

	_service.start_boot()

#endregion