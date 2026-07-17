# Notification Center architecture

Notification Center normalizes messages produced by other modules.

Notifications are immutable after creation except for lifecycle state.

Presentation components consume notifications through the application service.

Desktop-native notification adapters can be added behind infrastructure ports.