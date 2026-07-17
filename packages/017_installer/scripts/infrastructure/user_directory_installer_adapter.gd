class_name UserDirectoryInstallerAdapter
extends InstallerFileSystemPort
## Restricts installation operations to one user:// root.


#region State

var _root_path: String
var _created_paths: PackedStringArray = PackedStringArray()

#endregion


#region Construction

func _init(root_path: String) -> void:
	assert(
		root_path.begins_with("user://"),
		"Installer root must use user://."
	)

	_root_path = root_path.trim_suffix("/")

#endregion


#region InstallerFileSystemPort

func create_directory(relative_path: String) -> Result:
	var path_result := _resolve(relative_path)

	if path_result.is_failure():
		return path_result

	var absolute_path: String = path_result.get_value()
	var error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(absolute_path)
	)

	if error != OK and error != ERR_ALREADY_EXISTS:
		return _file_error(
			"Failed to create installation directory.",
			relative_path,
			error
		)

	_created_paths.append(absolute_path)

	return Result.success()


func write_text_file(
	relative_path: String,
	content: String,
	replace_existing: bool
) -> Result:
	var path_result := _resolve(relative_path)

	if path_result.is_failure():
		return path_result

	var path: String = path_result.get_value()

	if FileAccess.file_exists(path) and not replace_existing:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Installation file already exists.",
				{&"path": relative_path}
			)
		)

	var parent_path := path.get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(parent_path)
	)

	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return _file_error(
			"Failed to create parent directory.",
			relative_path,
			directory_error
		)

	var file := FileAccess.open(path, FileAccess.WRITE)

	if file == null:
		return _file_error(
			"Failed to open installation file.",
			relative_path,
			FileAccess.get_open_error()
		)

	file.store_string(content)
	file.close()
	_created_paths.append(path)

	return Result.success()


func remove_file(relative_path: String) -> Result:
	var path_result := _resolve(relative_path)

	if path_result.is_failure():
		return path_result

	var path: String = path_result.get_value()

	if not FileAccess.file_exists(path):
		return Result.success()

	var error := DirAccess.remove_absolute(
		ProjectSettings.globalize_path(path)
	)

	if error != OK:
		return _file_error(
			"Failed to remove installation file.",
			relative_path,
			error
		)

	return Result.success()


func file_exists(relative_path: String) -> bool:
	var path_result := _resolve(relative_path)

	if path_result.is_failure():
		return false

	return FileAccess.file_exists(path_result.get_value())


func rollback() -> Result:
	for index in range(
		_created_paths.size() - 1,
		-1,
		-1
	):
		var path := _created_paths[index]

		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(
				ProjectSettings.globalize_path(path)
			)

	_created_paths.clear()

	return Result.success()

#endregion


#region Private methods

func _resolve(relative_path: String) -> Result:
	var normalized := relative_path.strip_edges()

	if (
		normalized.is_empty()
		or normalized.is_absolute_path()
		or normalized.contains("..")
		or normalized.begins_with("/")
	):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Installer path is unsafe.",
				{&"path": relative_path}
			)
		)

	return Result.success(
		"%s/%s" % [_root_path, normalized]
	)


func _file_error(
	message: String,
	path: String,
	error: Error
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.UNKNOWN,
			message,
			{
				&"path": path,
				&"error": error,
			}
		)
	)

#endregion