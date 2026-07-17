class_name DemoEnvironmentProvider
extends EnvironmentProviderPort
## Provides deterministic local environmental data.


#region EnvironmentProviderPort

func fetch_zones() -> Result:
	var timestamp := int(
		Time.get_unix_time_from_system() * 1000.0
	)

	return Result.success(
		[
			{
				&"zone_id": &"command_room",
				&"display_name": "COMMAND ROOM",
				&"readings": [
					EnvironmentReading.new(
						EnvironmentMetricType.Value.TEMPERATURE,
						22.4,
						timestamp,
						&"demo_temperature_01"
					),
					EnvironmentReading.new(
						EnvironmentMetricType.Value.HUMIDITY,
						44.0,
						timestamp,
						&"demo_humidity_01"
					),
					EnvironmentReading.new(
						EnvironmentMetricType.Value.CO2,
						680.0,
						timestamp,
						&"demo_co2_01"
					),
				],
			},
			{
				&"zone_id": &"server_room",
				&"display_name": "SERVER ROOM",
				&"readings": [
					EnvironmentReading.new(
						EnvironmentMetricType.Value.TEMPERATURE,
						19.8,
						timestamp,
						&"demo_temperature_02"
					),
					EnvironmentReading.new(
						EnvironmentMetricType.Value.HUMIDITY,
						38.0,
						timestamp,
						&"demo_humidity_02"
					),
					EnvironmentReading.new(
						EnvironmentMetricType.Value.CO2,
						1120.0,
						timestamp,
						&"demo_co2_02"
					),
				],
			},
			{
				&"zone_id": &"garage",
				&"display_name": "GARAGE",
				&"readings": [
					EnvironmentReading.new(
						EnvironmentMetricType.Value.TEMPERATURE,
						15.5,
						timestamp,
						&"demo_temperature_03"
					),
					EnvironmentReading.new(
						EnvironmentMetricType.Value.HUMIDITY,
						72.0,
						timestamp,
						&"demo_humidity_03"
					),
					EnvironmentReading.new(
						EnvironmentMetricType.Value.PM25,
						31.0,
						timestamp,
						&"demo_pm25_03"
					),
				],
			},
		]
	)

#endregion