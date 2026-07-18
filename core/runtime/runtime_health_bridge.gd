class_name RuntimeHealthBridge
extends Node
## Propagates diagnostics state to Final HUD after shell startup.


#region State

var _diagnostics: DiagnosticsService
var _final_hud_service: FinalHudService

#endregion


#region Lifecycle

func _ready() -> void:
	_diagnostics = get_node_or_null(
		"/root/Diagnostics"
	) as DiagnosticsService

	if _diagnostics == null:
		return

	_diagnostics.health_state_changed.connect(
		_on_health_state_changed
	)

#endregion


#region Public API

## Attaches the active Final HUD service.
func attach_final_hud_service(
	service: FinalHudService
) -> void:
	_final_hud_service = service

#endregion


#region Event handling

func _on_health_state_changed(
	_previous_state: SystemHealthState.Value,
	current_state: SystemHealthState.Value
) -> void:
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	event_bus.publish(
		DomainEvent.new(
			&"hydra.runtime.health_changed",
			{
				&"state":
					SystemHealthState.to_string_name(
						current_state
					),
			}
		)
	)

#endregion