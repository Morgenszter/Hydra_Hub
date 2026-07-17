# Home Hub architecture

Home Hub is an aggregation boundary.

It consumes summarized state from other packages through ports and events.
It does not directly communicate with physical devices.

Device communication belongs to Package 010.
Environmental sensor processing belongs to Package 009.
Automation execution belongs to Package 012.