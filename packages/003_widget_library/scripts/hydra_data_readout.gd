class_name HydraDataReadout
extends WidgetBase
## Displays a label, value and measurement unit.


#region Exported properties

@export var label: String = "VALUE"
@export var value: String = "000"
@export var unit: String = ""

#endregion


#region Nodes

@onready var _label_node: RichTextLabel = %Label
@onready var _value_node: RichTextLabel = %Value

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	refresh()


func set_value(next_value: String) -> void:
	value = next_value
	refresh()


func refresh() -> void:
	if not is_node_ready():
		return

	_label_node.text = label
	_value_node.text = "%s %s" % [value, unit]

#endregion