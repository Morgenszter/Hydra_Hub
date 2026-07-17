# Plugin security

Plugins are untrusted until validated.

A plugin manifest declares requested capabilities.

Unknown capabilities are rejected.

Plugins may only access services explicitly granted by the composition root.

Native libraries, shell execution and unrestricted file access are outside the
default SDK contract.