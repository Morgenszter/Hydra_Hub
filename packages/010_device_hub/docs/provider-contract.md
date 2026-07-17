# Device provider contract

A provider must expose a stable provider identifier.

Discovery returns normalized DeviceDescriptor values.

State refresh returns DeviceStateSnapshot values.

Command execution receives DeviceCommand and returns a Result.

Provider implementations must not expose credentials through logs, scenes or
resources committed to the repository.