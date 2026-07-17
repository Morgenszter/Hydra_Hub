# Android permissions

HYDRA does not request permissions automatically.

Every permission request must be initiated by an explicit application use case.

A capability must report unavailable when its required permission is absent.

Permission denial must return a structured Result failure.