class_name HomeOverviewTest
extends RefCounted
## Provides executable HomeOverview tests.


#region Tests

static func run() -> void:
	var overview := HomeOverview.new(
		EntityId.generate(),
		"TEST HOME"
	)

	var rooms: Array[RoomSummary] = [
		RoomSummary.new(
			&"office",
			"OFFICE",
			true,
			22.0,
			3,
			0
		),
	]

	var result := overview.update_snapshot(
		HomeOperationalState.Value.NORMAL,
		SecurityState.Value.ARMED_HOME,
		1,
		1500.0,
		rooms
	)

	assert(result.is_success())
	assert(
		overview.get_operational_state()
		== HomeOperationalState.Value.NORMAL
	)
	assert(
		overview.get_security_state()
		== SecurityState.Value.ARMED_HOME
	)
	assert(overview.get_occupant_count() == 1)
	assert(
		is_equal_approx(
			overview.get_current_power_watts(),
			1500.0
		)
	)
	assert(overview.get_room_summaries().size() == 1)
	assert(not overview.pull_domain_events().is_empty())

#endregion