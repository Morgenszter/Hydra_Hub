class_name DiagnosticsConfiguration
extends Resource
## Stores Diagnostics runtime configuration.


#region Scheduling

@export_group("Scheduling")
@export var automatic_checks_enabled: bool = true
@export_range(1.0, 3600.0, 1.0) var check_interval_seconds: float = 15.0

#endregion


#region Retention

@export_group("Retention")
@export_range(1, 10000, 1) var maximum_findings: int = 500
@export_range(1, 1000, 1) var maximum_incidents: int = 100

#endregion


#region Presentation

@export_group("Presentation")
@export var show_healthy_findings: bool = true
@export var show_resolved_incidents: bool = false

#endregion