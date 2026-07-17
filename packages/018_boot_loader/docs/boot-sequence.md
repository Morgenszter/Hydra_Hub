# Boot sequence

Recommended startup order:

1. Validate configuration.
2. Initialize EventBus.
3. Initialize design and animation systems.
4. Initialize diagnostics.
5. Initialize feature services.
6. Validate installation state.
7. Load the main HUD scene.

Boot steps must remain deterministic and safe to retry.