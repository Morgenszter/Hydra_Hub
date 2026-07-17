class_name DiagnosticFindingTest
extends RefCounted
## Provides DiagnosticFinding tests.


#region Tests

static func run() -> void:
	var finding := DiagnosticFinding.new(
		&"test_probe",
		&"test.code",
		"TEST FINDING",
		"System operational.",
		DiagnosticSeverity.Value.INFO,
		true
	)

	assert(finding.get_probe_id() == &"test_probe")
	assert(finding.get_code() == &"test.code")
	assert(finding.is_healthy())
	assert(
		finding.get_severity()
		== DiagnosticSeverity.Value.INFO
	)

#endregion