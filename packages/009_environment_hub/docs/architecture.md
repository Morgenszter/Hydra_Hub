# Environment Hub architecture

Environment Hub normalizes environmental data behind a provider contract.

The domain layer owns readings, thresholds and zone state.

The application layer refreshes snapshots and publishes domain events.

The presentation layer consumes normalized snapshots and never talks directly
to sensors.