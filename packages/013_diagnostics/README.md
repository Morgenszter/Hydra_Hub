# Package 013 â€” Diagnostics

Diagnostics provides health checks, runtime metrics, incident records and the
system diagnostics panel for HYDRA AI HOME OS.

The package observes other modules through registered probes and EventBus
events. It does not modify feature-module state unless an explicit recovery
operation is invoked by another package.