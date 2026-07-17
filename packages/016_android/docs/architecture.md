# Android architecture

Package 016 is an infrastructure boundary.

Application and presentation code communicates with AndroidPlatformService.

AndroidPlatformService delegates native operations to AndroidPlatformPort.

The null adapter preserves desktop compatibility.

The runtime adapter may access Android APIs only after verifying that the
application is running on Android.