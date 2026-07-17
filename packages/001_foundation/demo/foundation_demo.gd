class_name FoundationDemo
extends Control
## Demonstrates Foundation event communication.


#region Lifecycle

func _ready() -> void:
	var bus := HydraEventBus.new()
	add_child(bus)

	bus.subscribe(
		&"hydra.foundation.demo",
		_on_demo_event
	)

	bus.publish(
		DomainEvent.new(
			&"hydra.foundation.demo",
			{&"message": "Foundation operational"}
		)
	)

#endregion


#region Event handlers

func _on_demo_event(event: DomainEvent) -> void:
	print(event.get_payload())

#endregion