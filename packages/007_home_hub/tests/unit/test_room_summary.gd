class_name RoomSummaryTest
extends RefCounted
## Provides executable RoomSummary tests.


#region Tests

static func run() -> void:
	var summary := RoomSummary.new(
		&"office",
		"OFFICE",
		true,
		22.5,
		5,
		1
	)

	assert(summary.get_room_id() == &"office")
	assert(summary.get_display_name() == "OFFICE")
	assert(summary.is_occupied())
	assert(
		is_equal_approx(
			summary.get_temperature_celsius(),
			22.5
		)
	)
	assert(summary.get_active_device_count() == 5)
	assert(summary.get_alert_count() == 1)

#endregion