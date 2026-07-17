# Installer architecture

Installer separates installation planning from file-system operations.

InstallationPlan owns validation and lifecycle state.

InstallerService executes operations through InstallerFileSystemPort.

The default adapter permits writes only under user://.

Rollback metadata records files created during the active installation.