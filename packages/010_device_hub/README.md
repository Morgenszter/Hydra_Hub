# Package 010 â€” Device Hub

Device Hub owns normalized smart-device identities, capabilities, operational
state, commands and the device-management interface.

Protocol-specific adapters implement DeviceProviderPort and remain isolated from
the domain and presentation layers.

## Responsibilities

Device Hub provides:

- Device discovery.
- Device inventory.
- Device state refresh.
- Capability-aware commands.
- Connection health.
- Device grouping and presentation.

Environment processing belongs to Package 009.
Automation orchestration belongs to Package 012.