# Debug Tools architecture

Debug Tools is isolated from feature-domain code.

Feature modules may register safe diagnostic commands.

Debug Tools does not execute operating-system shell commands.

The command registry receives structured arguments and returns Result.