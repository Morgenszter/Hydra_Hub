class_name DiagnosticsServiceTest
extends RefCounted
## Provides Diagnostics service composition tests.


#region Tests

static func run() -> void:
	var service := DiagnosticsService.new()
	var configuration := DiagnosticsConfiguration.new()
	var probe := RuntimeDiagnosticProbe.new()

	assert(service.configure(configuration).is_success())
	assert(service.register_probe(probe).is_success())

#endregion