# Device Hub architecture

Device Hub separates normalized device behavior from protocol implementations.

The domain layer owns device identity, capabilities and state transitions.

The application layer coordinates discovery, refresh and command execution.

The infrastructure layer contains adapters for protocols such as MQTT, Matter,
Home Assistant or vendor APIs.

The presentation layer displays normalized device state and never communicates
with protocol adapters directly.