class_name HydraThemeManager
extends Node
## Owns the active HYDRA design palette.


#region Signals

signal palette_changed(palette: HydraPalette)

#endregion


#region State

var _palette: HydraPalette

#endregion


#region Lifecycle

func _ready() -> void:
	if _palette == null:
		_palette = HydraPalette.new()

#endregion


#region Public API

func set_palette(palette: HydraPalette) -> void:
	assert(palette != null, "Theme palette cannot be null.")

	if _palette == palette:
		return

	_palette = palette
	palette_changed.emit(_palette)


func get_palette() -> HydraPalette:
	if _palette == null:
		_palette = HydraPalette.new()

	return _palette


func get_color(token: StringName) -> Color:
	var palette := get_palette()

	match token:
		&"background":
			return palette.background
		&"panel":
			return palette.panel
		&"panel_highlight":
			return palette.panel_highlight
		&"hologram_blue":
			return palette.hologram_blue
		&"hologram_blue_dim":
			return palette.hologram_blue_dim
		&"hologram_white":
			return palette.hologram_white
		&"gold":
			return palette.gold
		&"gold_dim":
			return palette.gold_dim
		&"success":
			return palette.success
		&"warning":
			return palette.warning
		&"danger":
			return palette.danger
		&"disabled":
			return palette.disabled
		_:
			push_warning("Unknown HYDRA color token: %s" % token)
			return Color.WHITE

#endregion