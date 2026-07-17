class_name FinalHudConfiguration
extends Resource
## Stores production HUD composition configuration.


#region Startup

@export_group("Startup")
@export var default_route_id: StringName = &"home"
@export var restore_last_route: bool = true
@export var show_boot_transition: bool = true

#endregion


#region Effects

@export_group("Effects")
@export var scanlines_enabled: bool = true
@export var vignette_enabled: bool = true
@export var glow_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var scanline_opacity: float = 0.14
@export_range(0.0, 1.0, 0.01) var vignette_strength: float = 0.42

#endregion


#region Debug

@export_group("Debug")
@export var debug_overlay_enabled: bool = OS.is_debug_build()

#endregion