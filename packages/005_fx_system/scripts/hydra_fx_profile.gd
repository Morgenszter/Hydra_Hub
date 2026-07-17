class_name HydraFxProfile
extends Resource
## Configures global HYDRA interface effects.


#region Feature switches

@export var crt_enabled: bool = true
@export var scanlines_enabled: bool = true
@export var noise_enabled: bool = true
@export var vignette_enabled: bool = true

#endregion


#region Intensities

@export_range(0.0, 1.0, 0.01) var scanline_intensity: float = 0.18
@export_range(0.0, 1.0, 0.01) var noise_intensity: float = 0.035
@export_range(0.0, 1.0, 0.01) var vignette_intensity: float = 0.35
@export_range(0.0, 4.0, 0.01) var glow_intensity: float = 1.25

#endregion