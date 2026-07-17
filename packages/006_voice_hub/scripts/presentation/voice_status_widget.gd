class_name VoiceStatusWidget
extends WidgetBase
## Displays the current Voice Hub state and microphone input level.


#region Constants

const MINIMUM_LEVEL_DB: float = -60.0
const MAXIMUM_LEVEL_DB: float = 0.0

#endregion


#region Exported properties

@export var idle_text: String = "VOICE LINK STANDBY"

#endregion


#region Nodes

@onready var _state_label: RichTextLabel = %StateLabel
@onready var _level_fill: ColorRect = %LevelFill
@onready var _status_indicator: ColorRect = %StatusIndicator

#endregion


#region State

var _state: VoiceSessionState.Value = VoiceSessionState.Value.IDLE
var _input_level_db: float = MINIMUM_LEVEL_DB

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	_refresh_state()
	_refresh_level()

#endregion


#region Public API

## Updates the displayed session state.
func set_session_state(
	state: VoiceSessionState.Value
) -> void:
	_state = state
	_refresh_state()


## Updates the displayed microphone level.
func set_input_level_db(level_db: float) -> void:
	_input_level_db = clampf(
		level_db,
		MINIMUM_LEVEL_DB,
		MAXIMUM_LEVEL_DB
	)
	_refresh_level()

#endregion


#region Private methods

func _refresh_state() -> void:
	if not is_node_ready():
		return

	var state_name := VoiceSessionState.to_string_name(
		_state
	)

	_state_label.text = (
		idle_text
		if _state == VoiceSessionState.Value.IDLE
		else "VOICE LINK  //  %s" % String(state_name).to_upper()
	)

	_status_indicator.color = _get_state_color()


func _refresh_level() -> void:
	if not is_node_ready():
		return

	var normalized_level := inverse_lerp(
		MINIMUM_LEVEL_DB,
		MAXIMUM_LEVEL_DB,
		_input_level_db
	)

	_level_fill.scale.x = clampf(
		normalized_level,
		0.0,
		1.0
	)


func _get_state_color() -> Color:
	match _state:
		VoiceSessionState.Value.IDLE:
			return Color("#40515b")
		VoiceSessionState.Value.ARMED:
			return Color("#d6aa48")
		VoiceSessionState.Value.LISTENING:
			return Color("#32d8ff")
		VoiceSessionState.Value.PROCESSING:
			return Color("#ffbf47")
		VoiceSessionState.Value.SPEAKING:
			return Color("#55f2a3")
		VoiceSessionState.Value.COMPLETED:
			return Color("#55f2a3")
		VoiceSessionState.Value.CANCELLED:
			return Color("#40515b")
		VoiceSessionState.Value.FAILED:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion