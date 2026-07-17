# Boot Loader architecture

Boot Loader executes registered steps in ascending order.

Every step returns Result.

A failed critical step stops startup.

A failed optional step is recorded and startup continues.

The final scene transition is performed only after all critical steps succeed.