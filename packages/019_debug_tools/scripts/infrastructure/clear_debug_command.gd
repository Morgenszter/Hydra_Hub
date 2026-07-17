class_name ClearDebugCommand
extends DebugCommand
## Requests Debug Tools output clearing.


#region DebugCommand

func get_command_id() -> StringName:
	return &"clear"


func get_description() -> String:
	return "Clears debug console output."


func get_usage() -> String:
	return "clear"


func execute(_arguments: PackedStringArray) -> Result:
	return Result.success(
		{
			&"clear_output": true,
		}
	)

#endregion