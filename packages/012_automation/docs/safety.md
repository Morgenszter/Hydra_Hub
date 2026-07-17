# Automation safety

Automation must prevent unbounded recursive execution.

Every execution receives a correlation identifier and recursion depth.

A rule may define a cooldown interval.

The runtime limits concurrent executions and action count.

Actions affecting locks, alarms, security modes or external communication should
require explicit approval through a policy implementation.