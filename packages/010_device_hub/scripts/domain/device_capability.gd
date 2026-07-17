class_name DeviceCapability
extends RefCounted
## Defines normalized device capability identifiers.


#region Values

enum Value {
	POWER,
	DIMMER,
	COLOR,
	TEMPERATURE,
	HUMIDITY,
	MOTION,
	CONTACT,
	LOCK,
	THERMOSTAT,
	ENERGY_METER,
	CAMERA,
	AUDIO,
	BATTERY,
}

#endregion


#region Public API

## Returns a stable capability identifier.
static func to_string_name(capability: Value) -> StringName:
	match capability:
		Value.POWER:
			return &"power"
		Value.DIMMER:
			return &"dimmer"
		Value.COLOR:
			return &"color"
		Value.TEMPERATURE:
			return &"temperature"
		Value.HUMIDITY:
			return &"humidity"
		Value.MOTION:
			return &"motion"
		Value.CONTACT:
			return &"contact"
		Value.LOCK:
			return &"lock"
		Value.THERMOSTAT:
			return &"thermostat"
		Value.ENERGY_METER:
			return &"energy_meter"
		Value.CAMERA:
			return &"camera"
		Value.AUDIO:
			return &"audio"
		Value.BATTERY:
			return &"battery"
		_:
			return &"unknown"

#endregion