class_name HydraStatusBadgeTest
extends RefCounted
## Provides status badge smoke tests.


#region Tests

static func run() -> void:
	var badge := HydraStatusBadge.new()
	badge.status = HydraStatusBadge.Status.ONLINE
	assert(badge.status == HydraStatusBadge.Status.ONLINE)

#endregion