class_name DesignSystemDemo
extends Control
## Displays the active HYDRA color palette.


#region Lifecycle

func _ready() -> void:
	var palette := HydraPalette.new()
	modulate = palette.hologram_white

#endregion