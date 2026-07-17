@abstract
class_name InstallerFileSystemPort
extends RefCounted
## Defines restricted installer file-system operations.


#region Public API

@abstract
func create_directory(relative_path: String) -> Result


@abstract
func write_text_file(
	relative_path: String,
	content: String,
	replace_existing: bool
) -> Result


@abstract
func remove_file(relative_path: String) -> Result


@abstract
func file_exists(relative_path: String) -> bool


@abstract
func rollback() -> Result

#endregion