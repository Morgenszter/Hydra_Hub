class_name DemoDeviceProvider
extends DeviceProviderPort
## Provides deterministic local devices for development and demos.


#region Constants

const PROVIDER_ID: StringName = &"demo"

#endregion


#region State

var _power_states: Dictionary[StringName, bool] = {
	&"command_light": true,
	&"living_light": false,
	&"garage_lock": true,
	&"server_fan": true,
}

#endregion


#region DeviceProviderPort

func get_provider_id() -> StringName:
	return PROVIDER_ID


func is_available() -> bool:
	return true


func discover_devices() -> Result:
	var devices: Array[DeviceDescriptor] = [
		DeviceDescriptor.new(
			&"command_light",
			PROVIDER_ID,
			"COMMAND LIGHT ARRAY",
			"HYDRA LABS",
			"HL-LIGHT-01",
			&"command_room",
			[
				DeviceCapability.Value.POWER,
				DeviceCapability.Value.DIMMER,
				DeviceCapability.Value.COLOR,
				DeviceCapability.Value.ENERGY_METER,
			]
		),
		DeviceDescriptor.new(
			&"living_light",
			PROVIDER_ID,
			"LIVING ROOM LIGHT",
			"HYDRA LABS",
			"HL-LIGHT-02",
			&"living_room",
			[
				DeviceCapability.Value.POWER,
				DeviceCapability.Value.DIMMER,
			]
		),
		DeviceDescriptor.new(
			&"garage_lock",
			PROVIDER_ID,
			"GARAGE SECURITY LOCK",
			"HYDRA SECURITY",
			"HS-LOCK-04",
			&"garage",
			[
				DeviceCapability.Value.LOCK,
				DeviceCapability.Value.BATTERY,
			]
		),
		DeviceDescriptor.new(
			&"server_fan",
			PROVIDER_ID,
			"SERVER COOLING ARRAY",
			"HYDRA INDUSTRIAL",
			"HI-FAN-09",
			&"server_room",
			[
				DeviceCapability.Value.POWER,
				DeviceCapability.Value.DIMMER,
				DeviceCapability.Value.ENERGY_METER,
			]
		),
	]

	return Result.success(devices)


func fetch_device_state(
	device_id: StringName
) -> Result:
	if not _power_states.has(device_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Demo provider does not contain the requested device.",
				{&"device_id": device_id}
			)
		)

	var timestamp := int(
		Time.get_unix_time_from_system() * 1000.0
	)
	var properties: Dictionary[StringName, Variant] = {
		&"power": _power_states[device_id],
	}

	match device_id:
		&"command_light":
			properties[&"brightness"] = 78.0
			properties[&"power_watts"] = 42.0
		&"living_light":
			properties[&"brightness"] = 0.0
			properties[&"power_watts"] = 0.0
		&"garage_lock":
			properties[&"locked"] = _power_states[device_id]
		&"server_fan":
			properties[&"speed_percent"] = 64.0
			properties[&"power_watts"] = 118.0

	var battery_percent := (
		82.0
		if device_id == &"garage_lock"
		else -1.0
	)

	return Result.success(
		DeviceStateSnapshot.new(
			device_id,
			DeviceConnectionState.Value.ONLINE,
			properties,
			timestamp,
			battery_percent,
			92.0
		)
	)


func execute_command(
	command: DeviceCommand
) -> Result:
	if command == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Demo provider command cannot be null."
			)
		)

	var device_id := command.get_device_id()

	if not _power_states.has(device_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Demo provider does not contain the requested device.",
				{&"device_id": device_id}
			)
		)

	match command.get_command_name():
		&"set_power":
			_power_states[device_id] = bool(
				command.get_argument(&"enabled", false)
			)
		&"toggle_power":
			_power_states[device_id] = not _power_states[device_id]
		&"lock":
			_power_states[device_id] = true
		&"unlock":
			_power_states[device_id] = false
		_:
			return Result.failure(
				DomainError.new(
					HydraErrors.INVALID_ARGUMENT,
					"Demo provider command is unsupported.",
					{
						&"device_id": device_id,
						&"command_name": command.get_command_name(),
					}
				)
			)

	return fetch_device_state(device_id)

#endregion