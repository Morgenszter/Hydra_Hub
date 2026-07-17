class_name HydraFxController
extends Node
## Applies an FX profile to registered materials.


#region Signals

signal profile_changed(profile: HydraFxProfile)

#endregion


#region State

var _profile: HydraFxProfile
var _materials: Array[ShaderMaterial] = []

#endregion


#region Lifecycle

func _ready() -> void:
	if _profile == null:
		_profile = HydraFxProfile.new()

#endregion


#region Public API

func set_profile(profile: HydraFxProfile) -> void:
	assert(profile != null, "FX profile cannot be null.")

	_profile = profile
	_apply_profile()
	profile_changed.emit(_profile)


func register_material(material: ShaderMaterial) -> void:
	if material == null or material in _materials:
		return

	_materials.append(material)
	_apply_to_material(material)


func unregister_material(material: ShaderMaterial) -> void:
	_materials.erase(material)


func get_profile() -> HydraFxProfile:
	if _profile == null:
		_profile = HydraFxProfile.new()

	return _profile

#endregion


#region Private methods

func _apply_profile() -> void:
	for material in _materials:
		_apply_to_material(material)


func _apply_to_material(material: ShaderMaterial) -> void:
	material.set_shader_parameter(
		"scanline_intensity",
		_profile.scanline_intensity if _profile.scanlines_enabled else 0.0
	)
	material.set_shader_parameter(
		"noise_intensity",
		_profile.noise_intensity if _profile.noise_enabled else 0.0
	)
	material.set_shader_parameter(
		"vignette_intensity",
		_profile.vignette_intensity if _profile.vignette_enabled else 0.0
	)

#endregion