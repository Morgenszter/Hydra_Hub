class_name PluginContext
extends RefCounted
## Provides explicitly granted services and extension registration.


#region State

var _services: Dictionary[StringName, Variant] = {}
var _extensions: Array[PluginExtensionDescriptor] = []

#endregion


#region Public API

## Grants one service to the plugin.
func grant_service(
	service_id: StringName,
	service: Variant
) -> Result:
	if service_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin service identifier cannot be empty."
			)
		)

	if service == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin service cannot be null.",
				{&"service_id": service_id}
			)
		)

	_services[service_id] = service

	return Result.success()


## Returns a granted service.
func get_service(
	service_id: StringName
) -> Variant:
	return _services.get(service_id)


## Returns whether a service was granted.
func has_service(
	service_id: StringName
) -> bool:
	return _services.has(service_id)


## Registers one plugin extension.
func register_extension(
	descriptor: PluginExtensionDescriptor
) -> Result:
	if descriptor == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin extension descriptor cannot be null."
			)
		)

	for extension in _extensions:
		if (
			extension.get_extension_id()
			== descriptor.get_extension_id()
		):
			return Result.failure(
				DomainError.new(
					HydraErrors.INVALID_STATE,
					"Plugin extension is already registered.",
					{
						&"extension_id":
							descriptor.get_extension_id(),
					}
				)
			)

	_extensions.append(descriptor)

	return Result.success()


## Returns registered plugin extensions.
func get_extensions() -> Array[PluginExtensionDescriptor]:
	return _extensions.duplicate()

#endregion