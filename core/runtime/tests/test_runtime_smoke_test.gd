class_name RuntimeSmokeTestTest
extends RefCounted
## Provides RuntimeSmokeTest contract tests.


#region Tests

static func run(tree: SceneTree) -> void:
	var result := RuntimeSmokeTest.run(tree)

	assert(result.is_success())
	assert(
		not (result.get_value() as PackedStringArray).is_empty()
	)

#endregion