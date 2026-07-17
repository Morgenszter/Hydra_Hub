@abstract
class_name DiagnosticProbePort
extends RefCounted
## Defines a diagnostic health-check boundary.


#region Public API

## Returns the stable probe identifier.
@abstract
func get_probe_id() -> StringName


## Returns the human-readable probe name.
@abstract
func get_display_name() -> String


## Executes the probe and returns Array[DiagnosticFinding].
@abstract
func run_probe() -> Result

#endregion