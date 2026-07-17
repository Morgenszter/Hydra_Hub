class_name FinalHudLayoutConstants
extends RefCounted
## Centralizes Final HUD layout dimensions.


#region Viewport

const VIEWPORT_SIZE: Vector2 = Vector2(1920.0, 1080.0)

#endregion


#region Primary regions

const TOP_BAR_HEIGHT: float = 72.0
const BOTTOM_BAR_HEIGHT: float = 108.0
const LEFT_RAIL_WIDTH: float = 260.0
const RIGHT_RAIL_WIDTH: float = 120.0

#endregion


#region Module viewport

const MODULE_VIEWPORT_POSITION: Vector2 = Vector2(
	LEFT_RAIL_WIDTH,
	TOP_BAR_HEIGHT
)

const MODULE_VIEWPORT_SIZE: Vector2 = Vector2(
	VIEWPORT_SIZE.x - LEFT_RAIL_WIDTH - RIGHT_RAIL_WIDTH,
	VIEWPORT_SIZE.y - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT
)

#endregion


#region Spacing

const LARGE_GAP: float = 24.0
const MEDIUM_GAP: float = 16.0
const SMALL_GAP: float = 8.0

#endregion