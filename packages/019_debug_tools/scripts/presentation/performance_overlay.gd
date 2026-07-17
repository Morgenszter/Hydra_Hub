class_name PerformanceOverlay
extends WidgetBase
## Displays live Godot performance metrics.


#region Nodes

@onready var _fps_label: RichTextLabel = %FpsLabel
@onready var _memory_label: RichTextLabel = %MemoryLabel
@onready var _objects_label: RichTextLabel = %ObjectsLabel
@onready var _draw_calls_label: RichTextLabel = %DrawCallsLabel

#endregion


#region State

var _service: DebugToolsService

#endregion


#region Public API

## Binds the overlay to DebugToolsService.
func bind_service(service: DebugToolsService) -> void:
	assert(service != null, "Debug Tools service cannot be null.")

	_disconnect_service()
	_service = service
	_service.performance_updated.connect(
		_on_performance_updated
	)

	_on_performance_updated(
		_service.get_performance_metrics()
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.performance_updated.is_connected(
		_on_performance_updated
	):
		_service.performance_updated.disconnect(
			_on_performance_updated
		)


func _on_performance_updated(metrics: Dictionary) -> void:
	_fps_label.text = "FPS  //  %d" % int(
		metrics.get(&"fps", 0.0)
	)
	_memory_label.text = "MEMORY  //  %.2f MiB" % (
		float(metrics.get(&"static_memory_bytes", 0.0))
		/ 1048576.0
	)
	_objects_label.text = (
		"OBJECTS  //  %d    NODES  //  %d"
		% [
			int(metrics.get(&"object_count", 0.0)),
			int(metrics.get(&"node_count", 0.0)),
		]
	)
	_draw_calls_label.text = "DRAW CALLS  //  %d" % int(
		metrics.get(&"draw_calls", 0.0)
	)

#endregion