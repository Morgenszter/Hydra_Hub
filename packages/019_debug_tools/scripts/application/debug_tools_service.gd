class_name DebugToolsService
extends Node
## Coordinates debug logging, commands and runtime telemetry.


#region Signals

signal log_entry_added(entry: DebugLogEntry)
signal logs_cleared()
signal command_executed(
	command_line: String,
	result: Result
)
signal performance_updated(metrics: Dictionary)

#endregion


#region State

var _configuration: DebugToolsConfiguration
var _registry: DebugCommandRegistry
var _entries: Array[DebugLogEntry] = []
var _performance_timer: Timer

#endregion


#region Lifecycle

func _ready() -> void:
	_performance_timer = Timer.new()
	_performance_timer.name = "DebugPerformanceTimer"
	_performance_timer.one_shot = false
	_performance_timer.timeout.connect(
		_on_performance_timer_timeout
	)
	add_child(_performance_timer)

#endregion


#region Public API

## Configures Debug Tools.
func configure(
	configuration: DebugToolsConfiguration,
	registry: DebugCommandRegistry
) -> Result:
	if configuration == null or registry == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Debug Tools configuration and registry are required."
			)
		)

	_configuration = configuration
	_registry = registry
	_performance_timer.wait_time = (
		configuration.performance_refresh_seconds
	)

	return Result.success()


## Starts configured debug services.
func start() -> Result:
	if _configuration == null or _registry == null:
		return _not_configured()

	if not _configuration.enabled:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Debug Tools is disabled."
			)
		)

	if _configuration.performance_overlay_enabled:
		_performance_timer.start()

	return Result.success()


## Stops debug telemetry.
func stop() -> void:
	_performance_timer.stop()


## Adds one debug log entry.
func log(
	level: DebugLogLevel.Value,
	source: StringName,
	message: String,
	metadata: Dictionary[StringName, Variant] = {}
) -> Result:
	if _configuration == null:
		return _not_configured()

	var entry := DebugLogEntry.new(
		level,
		source,
		message,
		metadata
	)

	_entries.append(entry)

	while _entries.size() > _configuration.maximum_log_entries:
		_entries.pop_front()

	log_entry_added.emit(entry)

	return Result.success(entry)


## Clears all debug logs.
func clear_logs() -> void:
	_entries.clear()
	logs_cleared.emit()


## Executes a structured debug command.
func execute_command(
	command_line: String
) -> Result:
	if _registry == null:
		return _not_configured()

	var result := _registry.execute_line(command_line)
	command_executed.emit(command_line, result)

	return result


## Returns current debug log entries.
func get_entries() -> Array[DebugLogEntry]:
	return _entries.duplicate()


## Returns current performance metrics.
func get_performance_metrics() -> Dictionary:
	return {
		&"fps": Performance.get_monitor(
			Performance.TIME_FPS
		),
		&"static_memory_bytes": Performance.get_monitor(
			Performance.MEMORY_STATIC
		),
		&"object_count": Performance.get_monitor(
			Performance.OBJECT_COUNT
		),
		&"node_count": Performance.get_monitor(
			Performance.OBJECT_NODE_COUNT
		),
		&"draw_calls": Performance.get_monitor(
			Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
		),
		&"process_time": Performance.get_monitor(
			Performance.TIME_PROCESS
		),
		&"physics_process_time": Performance.get_monitor(
			Performance.TIME_PHYSICS_PROCESS
		),
	}

#endregion


#region Private methods

func _on_performance_timer_timeout() -> void:
	performance_updated.emit(
		get_performance_metrics()
	)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Debug Tools is not configured."
		)
	)

#endregion