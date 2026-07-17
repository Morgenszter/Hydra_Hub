# Debug Tools security

Debug Tools must remain disabled in production builds by default.

Commands must not expose secrets, authentication tokens or private user data.

Arbitrary script evaluation and shell execution are prohibited.

Destructive commands require explicit registration and confirmation policy.