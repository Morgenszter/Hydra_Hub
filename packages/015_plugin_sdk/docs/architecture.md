# Plugin SDK architecture

Plugin SDK provides contracts only.

Plugin implementations depend on Plugin SDK.

The application composition root owns plugin discovery and loading.

Plugins receive explicitly granted services instead of resolving unrestricted
autoloads.