class_name RuntimeDebugCommand
extends DebugCommand
## Returns current Godot runtime metrics.


#region DebugCommand

func get_command_id() -> StringName:
	return &"runtime"


func get_description() -> String:
	return "Displays runtime performance information."


func get_usage() -> String:
	return "runtime"


func execute(_arguments: PackedStringArray) -> Result:
	var fps := Performance.get_monitor(
		Performance.TIME_FPS
	)
	var memory_bytes := Performance.get_monitor(
		Performance.MEMORY_STATIC
	)
	var object_count := Performance.get_monitor(
		Performance.OBJECT_COUNT
	)
	var node_count := Performance.get_monitor(
		Performance.OBJECT_NODE_COUNT
	)

	var output := (
		"FPS: %d\n"
		+ "STATIC MEMORY: %.2f MiB\n"
		+ "OBJECTS: %d\n"
		+ "NODES: %d"
	) % [
		int(fps),
		memory_bytes / 1048576.0,
		int(object_count),
		int(node_count),
	]

	return Result.success(output)

#endregion