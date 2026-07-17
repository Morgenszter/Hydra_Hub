@abstract
class_name EnvironmentProviderPort
extends RefCounted
## Defines the boundary for retrieving environmental zone snapshots.


#region Public API

## Returns a Result containing an array of zone dictionaries.
@abstract
func fetch_zones() -> Result

#endregion