class_name HydraFxProfileTest
extends RefCounted
## Provides FX profile smoke tests.


#region Tests

static func run() -> void:
	var profile := HydraFxProfile.new()
	assert(profile.scanline_intensity >= 0.0)
	assert(profile.scanline_intensity <= 1.0)
	assert(profile.glow_intensity > 0.0)

#endregion