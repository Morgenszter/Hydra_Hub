class_name UserDirectoryInstallerAdapterTest
extends RefCounted
## Provides installer file-system adapter tests.


#region Tests

static func run() -> void:
	var adapter := UserDirectoryInstallerAdapter.new(
		"user://hydra_installer_test"
	)

	assert(
		adapter.create_directory("config").is_success()
	)
	assert(
		adapter.write_text_file(
			"config/test.txt",
			"HYDRA",
			true
		).is_success()
	)
	assert(adapter.file_exists("config/test.txt"))
	assert(adapter.rollback().is_success())

#endregion