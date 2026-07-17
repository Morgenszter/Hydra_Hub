# Diagnostics architecture

Diagnostics is an observability package.

Probes collect isolated health information.

DiagnosticsService executes probes, aggregates findings and publishes health
changes.

Presentation components display normalized findings without depending on probe
implementations.