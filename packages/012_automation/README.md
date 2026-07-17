# Package 012 â€” Automation

Automation owns rule definitions, trigger evaluation, condition evaluation,
action execution and execution history.

The package coordinates other modules through ports and EventBus events. It does
not directly communicate with physical devices, AI providers or environmental
sensors.

## Safety

Rules are disabled by default after validation failure.

Destructive actions require an explicit approval policy.

Execution recursion and excessive trigger frequency are limited by runtime
configuration.