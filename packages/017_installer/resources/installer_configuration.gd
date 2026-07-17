class_name InstallerConfiguration
extends Resource
## Stores Installer runtime configuration.


#region Paths

@export_group("Paths")
@export var installation_root: String = "user://hydra"
@export var backup_root: String = "user://hydra_backups"

#endregion


#region Behavior

@export_group("Behavior")
@export var allow_overwrite: bool = false
@export var create_backups: bool = true
@export var validate_after_installation: bool = true
@export var rollback_on_failure: bool = true

#endregion


#region Limits

@export_group("Limits")
@export_range(1, 100000, 1) var maximum_operations: int = 10000
@export_range(1, 1073741824, 1024) var maximum_file_size_bytes: int = 67108864

#endregion