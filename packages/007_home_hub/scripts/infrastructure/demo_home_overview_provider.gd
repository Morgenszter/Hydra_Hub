class_name DemoHomeOverviewProvider
extends HomeOverviewProviderPort
## Provides deterministic local data for demos and development.


#region HomeOverviewProviderPort

func fetch_overview(_home_id: StringName) -> Result:
	var rooms: Array[RoomSummary] = [
		RoomSummary.new(
			&"command_room",
			"COMMAND ROOM",
			true,
			22.4,
			6,
			0
		),
		RoomSummary.new(
			&"living_room",
			"LIVING ROOM",
			true,
			21.8,
			4,
			0
		),
		RoomSummary.new(
			&"server_room",
			"SERVER ROOM",
			false,
			19.6,
			11,
			1
		),
		RoomSummary.new(
			&"garage",
			"GARAGE",
			false,
			16.2,
			2,
			0
		),
	]

	return Result.success(
		{
			&"operational_state":
				HomeOperationalState.Value.NORMAL,
			&"security_state":
				SecurityState.Value.ARMED_HOME,
			&"occupant_count": 2,
			&"current_power_watts": 1840.0,
			&"rooms": rooms,
		}
	)

#endregion