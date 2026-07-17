# Installer security

Paths containing traversal segments are rejected.

Absolute operating-system paths are rejected by the default adapter.

Installer packages may write only to approved user:// locations.

Existing files are not overwritten unless the installation plan explicitly
allows replacement.

Executable files are not launched by Installer.