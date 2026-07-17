@abstract
class_name DebugCommand
extends RefCounted
## Defines a safe structured debug command.


#region Public API

## Returns the stable command identifier.
@abstract
func get_command_id() -> StringName


## Returns a human-readable description.
@abstract
func get_description() -> String


## Returns a usage string.
@abstract
func get_usage() -> String


## Executes the command.
@abstract
func execute(arguments: PackedStringArray) -> Result

#endregion