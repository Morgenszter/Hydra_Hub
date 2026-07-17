class_name HydraErrors
extends RefCounted
## Defines stable machine-readable error codes.


#region General

const UNKNOWN: StringName = &"hydra.error.unknown"
const INVALID_ARGUMENT: StringName = &"hydra.error.invalid_argument"
const INVALID_STATE: StringName = &"hydra.error.invalid_state"
const VALUE_REQUIRED: StringName = &"hydra.error.value_required"

#endregion


#region Services

const SERVICE_NOT_FOUND: StringName = &"hydra.service.not_found"
const SERVICE_ALREADY_REGISTERED: StringName = \
	&"hydra.service.already_registered"

#endregion


#region Modules

const MODULE_INITIALIZATION_FAILED: StringName = \
	&"hydra.module.initialization_failed"
const MODULE_START_FAILED: StringName = &"hydra.module.start_failed"
const MODULE_STOP_FAILED: StringName = &"hydra.module.stop_failed"

#endregion