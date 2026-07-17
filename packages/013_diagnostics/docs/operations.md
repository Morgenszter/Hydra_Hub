# Diagnostics operations

A diagnostic probe must be deterministic, bounded and non-destructive.

Probe failures are converted into critical findings.

Sensitive values must not be included in findings, logs or exported diagnostic
reports.

Health checks should remain safe to execute repeatedly.