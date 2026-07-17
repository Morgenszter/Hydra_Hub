class_name InstallerDemo
extends Control
## Demonstrates installation into user://hydra_demo.


#region Nodes

@onready var _panel: InstallerPanel = %InstallerPanel

#endregion


#region State

var _service: InstallerService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = InstallerService.new()
	_service.name = "InstallerService"
	add_child(_service)

	var configuration := InstallerConfiguration.new()
	configuration.installation_root = "user://hydra_demo"
	configuration.allow_overwrite = true

	var adapter := UserDirectoryInstallerAdapter.new(
		configuration.installation_root
	)

	_service.configure(configuration, adapter)
	_panel.bind_service(_service)

	var manifest := InstallationManifest.new()
	manifest.package_id = &"demo_package"
	manifest.display_name = "DEMO PACKAGE"
	manifest.version = "0.1.0"

	var operations: Array[InstallationOperation] = [
		InstallationOperation.new(
			InstallationOperation.Type.CREATE_DIRECTORY,
			"config"
		),
		InstallationOperation.new(
			InstallationOperation.Type.WRITE_TEXT_FILE,
			"config/demo.cfg",
			"[demo]\ninstalled=true\n",
			true
		),
	]

	var plan := InstallationPlan.new(
		EntityId.generate(),
		manifest,
		operations
	)

	_service.install(plan)

#endregion