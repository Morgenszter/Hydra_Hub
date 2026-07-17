class_name EnvironmentMetricType
extends RefCounted
## Defines normalized environmental metric identifiers.


#region Values

enum Value {
	TEMPERATURE,
	HUMIDITY,
	CO2,
	PM25,
	PRESSURE,
	ILLUMINANCE,
	NOISE,
	VOC_INDEX,
}

#endregion


#region Public API

## Returns a stable metric identifier.
static func to_string_name(metric: Value) -> StringName:
	match metric:
		Value.TEMPERATURE:
			return &"temperature"
		Value.HUMIDITY:
			return &"humidity"
		Value.CO2:
			return &"co2"
		Value.PM25:
			return &"pm25"
		Value.PRESSURE:
			return &"pressure"
		Value.ILLUMINANCE:
			return &"illuminance"
		Value.NOISE:
			return &"noise"
		Value.VOC_INDEX:
			return &"voc_index"
		_:
			return &"unknown"


## Returns the standard display unit.
static func get_unit(metric: Value) -> String:
	match metric:
		Value.TEMPERATURE:
			return "Â°C"
		Value.HUMIDITY:
			return "%"
		Value.CO2:
			return "ppm"
		Value.PM25:
			return "Âµg/mÂł"
		Value.PRESSURE:
			return "hPa"
		Value.ILLUMINANCE:
			return "lx"
		Value.NOISE:
			return "dB"
		Value.VOC_INDEX:
			return "INDEX"
		_:
			return ""

#endregion