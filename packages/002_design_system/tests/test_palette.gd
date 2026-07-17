class_name HydraPaletteTest
extends RefCounted
## Provides palette smoke tests.


#region Tests

static func run() -> void:
	var palette := HydraPalette.new()
	assert(palette.hologram_blue.a == 1.0)
	assert(palette.background != palette.panel)

#endregion