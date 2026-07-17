class_name HydraAnimationProfileTest
extends RefCounted
## Provides animation profile smoke tests.


#region Tests

static func run() -> void:
	var profile := HydraAnimationProfile.new()
	assert(profile.fast_duration > 0.0)
	assert(profile.standard_duration >= profile.fast_duration)

#endregion