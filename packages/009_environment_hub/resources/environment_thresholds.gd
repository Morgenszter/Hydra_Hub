class_name EnvironmentThresholds
extends Resource
## Defines warning and critical environmental thresholds.


#region Temperature

@export_group("Temperature")
@export var minimum_temperature_warning_celsius: float = 16.0
@export var minimum_temperature_critical_celsius: float = 10.0
@export var maximum_temperature_warning_celsius: float = 28.0
@export var maximum_temperature_critical_celsius: float = 35.0

#endregion


#region Humidity

@export_group("Humidity")
@export_range(0.0, 100.0, 0.5) var minimum_humidity_warning_percent: float = 30.0
@export_range(0.0, 100.0, 0.5) var maximum_humidity_warning_percent: float = 65.0
@export_range(0.0, 100.0, 0.5) var maximum_humidity_critical_percent: float = 80.0

#endregion


#region Air quality

@export_group("Air Quality")
@export var co2_warning_ppm: float = 1000.0
@export var co2_critical_ppm: float = 2000.0
@export var pm25_warning_ug_m3: float = 25.0
@export var pm25_critical_ug_m3: float = 50.0
@export var voc_warning_index: float = 150.0
@export var voc_critical_index: float = 250.0

#endregion