@abstract
class_name EventBusPort
extends Node
## Defines the cross-package event communication contract.


#region Public API

@abstract
func publish(event: DomainEvent) -> void


@abstract
func subscribe(
	event_name: StringName,
	handler: Callable
) -> Result


@abstract
func unsubscribe(
	event_name: StringName,
	handler: Callable
) -> Result

#endregion