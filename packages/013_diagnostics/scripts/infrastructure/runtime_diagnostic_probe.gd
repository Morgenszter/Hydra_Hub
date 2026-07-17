class_name RuntimeDiagnosticProbe
extends DiagnosticProbePort
## Reports Godot runtime and memory diagnostics.


#region Constants

const PROBE_ID: StringName = &"runtime"

#endregion


#region DiagnosticProbePort

func get_probe_id() -> StringName:
	return PROBE_ID


func get_display_name() -> String:
	return "GODOT RUNTIME"


func run_probe() -> Result:
	var findings: Array[DiagnosticFinding] = []
	var static_memory := Performance.get_monitor(
		Performance.MEMORY_STATIC
	)
	var object_count := Performance.get_monitor(
		Performance.OBJECT_COUNT
	)
	var node_count := Performance.get_monitor(
		Performance.OBJECT_NODE_COUNT
	)
	var fps := Performance.get_monitor(
		Performance.TIME_FPS
	)

	findings.append(
		DiagnosticFinding.new(
			PROBE_ID,
			&"runtime.engine",
			"ENGINE RUNTIME",
			"Godot runtime is responding.",
			DiagnosticSeverity.Value.NOTICE,
			true,
			{
				&"version": Engine.get_version_info(),
				&"fps": fps,
			}
		)
	)

	var memory_warning := static_memory >= 1073741824.0

	findings.append(
		DiagnosticFinding.new(
			PROBE_ID,
			&"runtime.memory",
			"STATIC MEMORY",
			"Static memory: %.2f MiB" % (
				static_memory / 1048576.0
			),
			(
				DiagnosticSeverity.Value.WARNING
				if memory_warning
				else DiagnosticSeverity.Value.INFO
			),
			not memory_warning,
			{
				&"bytes": static_memory,
			}
		)
	)

	findings.append(
		DiagnosticFinding.new(
			PROBE_ID,
			&"runtime.objects",
			"OBJECT INVENTORY",
			"Objects: %d  Nodes: %d" % [
				int(object_count),
				int(node_count),
			],
			DiagnosticSeverity.Value.INFO,
			true,
			{
				&"object_count": object_count,
				&"node_count": node_count,
			}
		)
	)

	return Result.success(findings)

#endregion