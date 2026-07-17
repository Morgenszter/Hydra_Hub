class_name DebugCommandRegistry
extends RefCounted
## Stores and executes safe debug commands.


#region State

var _commands: Dictionary[StringName, DebugCommand] = {}

#endregion


#region Public API

## Registers one debug command.
func register_command(command: DebugCommand) -> Result:
	if command == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Debug command cannot be null."
			)
		)

	var command_id := command.get_command_id()

	if command_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Debug command requires command_id."
			)
		)

	if _commands.has(command_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_ALREADY_REGISTERED,
				"Debug command is already registered.",
				{&"command_id": command_id}
			)
		)

	_commands[command_id] = command

	return Result.success(command)


## Executes a command line.
func execute_line(command_line: String) -> Result:
	var normalized := command_line.strip_edges()

	if normalized.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Debug command line cannot be empty."
			)
		)

	var parts := normalized.split(
		" ",
		false
	)

	if parts.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Debug command line is invalid."
			)
		)

	var command_id := StringName(parts[0].to_lower())
	var command := _commands.get(command_id) as DebugCommand

	if command == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_NOT_FOUND,
				"Debug command was not found.",
				{&"command_id": command_id}
			)
		)

	var arguments := PackedStringArray()

	for index in range(1, parts.size()):
		arguments.append(parts[index])

	return command.execute(arguments)


## Returns registered commands.
func get_commands() -> Array[DebugCommand]:
	var result: Array[DebugCommand] = []

	for command: DebugCommand in _commands.values():
		result.append(command)

	result.sort_custom(
		func(left: DebugCommand, right: DebugCommand) -> bool:
			return (
				String(left.get_command_id())
				< String(right.get_command_id())
			)
	)

	return result

#endregion