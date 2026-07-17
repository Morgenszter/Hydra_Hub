class_name ManagedDevice
extends AggregateRoot
## Owns normalized state for one managed device.


#region Events

const EVENT_DISCOVERED: StringName = \
	&"hydra.device.discovered"
const EVENT_STATE_UPDATED: StringName = \
	&"hydra.device.state_updated"
const EVENT_CONNECTION_CHANGED: StringName = \
	&"hydra.device.connection_changed"
const EVENT_COMMAND_COMPLETED: StringName = \
	&"hydra.device.command_completed"
const EVENT_COMMAND_FAILED: StringName = \
	&"hydra.device.command_failed"

#endregion


#region State

var _descriptor: DeviceDescriptor
var _state: DeviceStateSnapshot

#endregion


#region Construction

## Creates a managed device from immutable metadata.
func _init(
	id: EntityId,
	descriptor: DeviceDescriptor
) -> void:
	super(id)

	assert(
		descriptor != null,
		"ManagedDevice requires a descriptor."
	)

	_descriptor = descriptor

	_record_domain_event(
		DomainEvent.new(
			EVENT_DISCOVERED,
			{
				&"device_id": descriptor.get_device_id(),
				&"provider_id": descriptor.get_provider_id(),
				&"display_name": descriptor.get_display_name(),
			}
		)
	)

#endregion


#region Public API

func get_descriptor() -> DeviceDescriptor:
	return _descriptor


func get_state() -> DeviceStateSnapshot:
	return _state


func get_device_id() -> StringName:
	return _descriptor.get_device_id()


## Applies a new state snapshot.
func update_state(
	state: DeviceStateSnapshot
) -> Result:
	if state == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Device state cannot be null."
			)
		)

	if state.get_device_id() != get_device_id():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Device state belongs to another device.",
				{
					&"expected_device_id": get_device_id(),
					&"actual_device_id": state.get_device_id(),
				}
			)
		)

	var previous_connection_state := (
		DeviceConnectionState.Value.UNKNOWN
		if _state == null
		else _state.get_connection_state()
	)

	_state = state
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_STATE_UPDATED,
			{
				&"device_id": get_device_id(),
				&"connection_state":
					DeviceConnectionState.to_string_name(
						state.get_connection_state()
					),
				&"properties": state.get_properties(),
			}
		)
	)

	if previous_connection_state != state.get_connection_state():
		_record_domain_event(
			DomainEvent.new(
				EVENT_CONNECTION_CHANGED,
				{
					&"device_id": get_device_id(),
					&"previous_state":
						DeviceConnectionState.to_string_name(
							previous_connection_state
						),
					&"current_state":
						DeviceConnectionState.to_string_name(
							state.get_connection_state()
						),
				}
			)
		)

	return Result.success()


## Records successful command execution.
func record_command_completed(
	command: DeviceCommand
) -> void:
	if command == null:
		return

	_record_domain_event(
		DomainEvent.new(
			EVENT_COMMAND_COMPLETED,
			{
				&"device_id": get_device_id(),
				&"command_id": command.get_command_id(),
				&"command_name": command.get_command_name(),
			}
		)
	)


## Records failed command execution.
func record_command_failed(
	command: DeviceCommand,
	error: DomainError
) -> void:
	if command == null or error == null:
		return

	_record_domain_event(
		DomainEvent.new(
			EVENT_COMMAND_FAILED,
			{
				&"device_id": get_device_id(),
				&"command_id": command.get_command_id(),
				&"command_name": command.get_command_name(),
				&"error": error.to_dictionary(),
			}
		)
	)

#endregion