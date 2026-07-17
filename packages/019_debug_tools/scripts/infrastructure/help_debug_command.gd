class_name HelpDebugCommand
extends DebugCommand
## Prints all registered debug commands.


#region State

var _registry: DebugCommandRegistry

#endregion


#region Construction

func _init(registry: DebugCommandRegistry) -> void:
	assert(
		registry != null,
		"HelpDebugCommand requires registry."
	)

	_registry = registry

#endregion


#region DebugCommand

func get_command_id() -> StringName:
	return &"help"


func get_description() -> String:
	return "Lists registered debug commands."


func get_usage() -> String:
	return "help"


func execute(_arguments: PackedStringArray) -> Result:
	var lines := PackedStringArray()

	for command in _registry.get_commands():
		lines.append(
			"%s - %s"
			% [
				command.get_usage(),
				command.get_description(),
			]
		)

	return Result.success(
		"\n".join(lines)
	)

#endregion