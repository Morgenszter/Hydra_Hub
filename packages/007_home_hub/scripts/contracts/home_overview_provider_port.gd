@abstract
class_name HomeOverviewProviderPort
extends RefCounted
## Defines the boundary for retrieving aggregated home state.


#region Public API

## Returns a Result containing a dictionary snapshot.
@abstract
func fetch_overview(home_id: StringName) -> Result

#endregion