# Central Hub architecture

Central Hub is a presentation-composition package.

It owns navigation state, registered route metadata and module activation
requests.

It communicates with packages through EventBus events and does not instantiate
infrastructure implementations directly.