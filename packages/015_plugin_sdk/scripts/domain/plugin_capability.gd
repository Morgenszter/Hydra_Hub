class_name PluginCapability
extends RefCounted
## Defines supported plugin capability identifiers.


#region Constants

const EVENT_SUBSCRIPTION: StringName = &"event_subscription"
const EVENT_PUBLICATION: StringName = &"event_publication"
const UI_WIDGET: StringName = &"ui_widget"
const UI_PANEL: StringName = &"ui_panel"
const DEVICE_PROVIDER: StringName = &"device_provider"
const AI_PROVIDER: StringName = &"ai_provider"
const AUTOMATION_EXECUTOR: StringName = &"automation_executor"
const DIAGNOSTIC_PROBE: StringName = &"diagnostic_probe"

#endregion


#region Public API

## Returns all capabilities supported by the SDK.
static func get_supported() -> Array[StringName]:
	return [
		EVENT_SUBSCRIPTION,
		EVENT_PUBLICATION,
		UI_WIDGET,
		UI_PANEL,
		DEVICE_PROVIDER,
		AI_PROVIDER,
		AUTOMATION_EXECUTOR,
		DIAGNOSTIC_PROBE,
	]


## Returns whether a capability is supported.
static func is_supported(
	capability: StringName
) -> bool:
	return capability in get_supported()

#endregion