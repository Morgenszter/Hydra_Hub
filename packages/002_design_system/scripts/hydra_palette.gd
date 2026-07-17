class_name HydraPalette
extends Resource
## Stores configurable HYDRA interface colors.


#region Colors

@export_group("Surfaces")
@export var background: Color = Color("#03080d")
@export var panel: Color = Color("#071722")
@export var panel_highlight: Color = Color("#0d2b3c")

@export_group("Holographic")
@export var hologram_blue: Color = Color("#32d8ff")
@export var hologram_blue_dim: Color = Color("#12647a")
@export var hologram_white: Color = Color("#d9f8ff")

@export_group("Accents")
@export var gold: Color = Color("#d6aa48")
@export var gold_dim: Color = Color("#6e5627")

@export_group("States")
@export var success: Color = Color("#55f2a3")
@export var warning: Color = Color("#ffbf47")
@export var danger: Color = Color("#ff4f62")
@export var disabled: Color = Color("#40515b")

#endregion