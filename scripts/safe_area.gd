extends MarginContainer

@onready var frame: TextureRect = $"../"

# offsety dopasowane DO TEJ RAMY (ręcznie raz, potem działa zawsze)
const PAD_LEFT   := 220
const PAD_RIGHT  := 300
const PAD_TOP    := 130
const PAD_BOTTOM := 160

const BASE_RES := Vector2(1920, 1080)

func _process(_delta):
	_apply()

func _apply():
	if frame == null or frame.texture == null:
		return

	var screen = get_viewport_rect().size

	var scale_factor = min(
		screen.x / BASE_RES.x,
		screen.y / BASE_RES.y
	)

	add_theme_constant_override("margin_left", PAD_LEFT * scale_factor)
	add_theme_constant_override("margin_right", PAD_RIGHT * scale_factor)
	add_theme_constant_override("margin_top", PAD_TOP * scale_factor)
	add_theme_constant_override("margin_bottom", PAD_BOTTOM * scale_factor)
