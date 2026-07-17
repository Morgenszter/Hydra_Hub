class_name UUID
extends RefCounted
## Generates RFC 4122-compatible version 4 UUID strings.
##
## The implementation uses cryptographically secure random bytes provided by
## Godot's Crypto service.


#region Constants

const UUID_BYTE_COUNT: int = 16
const VERSION_BYTE_INDEX: int = 6
const VARIANT_BYTE_INDEX: int = 8
const VERSION_MASK: int = 0x0F
const VERSION_4_FLAG: int = 0x40
const VARIANT_MASK: int = 0x3F
const VARIANT_RFC_4122_FLAG: int = 0x80

#endregion


#region Public API

## Generates a lowercase UUID version 4 string.
static func v4() -> String:
	var crypto := Crypto.new()
	var bytes := crypto.generate_random_bytes(UUID_BYTE_COUNT)

	assert(
		bytes.size() == UUID_BYTE_COUNT,
		"UUID generation failed."
	)

	bytes[VERSION_BYTE_INDEX] = (
		bytes[VERSION_BYTE_INDEX] & VERSION_MASK
	) | VERSION_4_FLAG

	bytes[VARIANT_BYTE_INDEX] = (
		bytes[VARIANT_BYTE_INDEX] & VARIANT_MASK
	) | VARIANT_RFC_4122_FLAG

	var hexadecimal := bytes.hex_encode()

	return "%s-%s-%s-%s-%s" % [
		hexadecimal.substr(0, 8),
		hexadecimal.substr(8, 4),
		hexadecimal.substr(12, 4),
		hexadecimal.substr(16, 4),
		hexadecimal.substr(20, 12),
	]

#endregion
