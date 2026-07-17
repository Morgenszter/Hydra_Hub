class_name CrtOverlay
extends ColorRect
## Full-screen CRT and scanline presentation overlay.


#region Exported properties

@export var profile: HydraFxProfile

#endregion


#region Lifecycle

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if profile == null:
		profile = HydraFxProfile.new()

	_apply_profile()

#endregion


#region Public API

func apply_profile(next_profile: HydraFxProfile) -> void:
	assert(next_profile != null, "FX profile cannot be null.")

	profile = next_profile
	_apply_profile()

#endregion


#region Private methods

func _apply_profile() -> void:
	var shader_material := material as ShaderMaterial

	if shader_material == null:
		return

	shader_material.set_shader_parameter(
		"scanline_intensity",
		profile.scanline_intensity
	)
	shader_material.set_shader_parameter(
		"noise_intensity",
		profile.noise_intensity
	)
	shader_material.set_shader_parameter(
		"vignette_intensity",
		profile.vignette_intensity
	)

#endregion