# Package 018 â€” Boot Loader

Boot Loader owns deterministic application startup, ordered boot steps,
progress reporting, failure handling and transition to the main HYDRA scene.

Boot Loader does not own feature-module business logic.

Each module contributes a BootStep implementation through the composition root.