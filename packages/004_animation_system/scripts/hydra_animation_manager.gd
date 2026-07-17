class_name HydraAnimationManager
extends Node
## Creates and tracks all HYDRA interface tweens.


#region Signals

signal animation_started(animation_id: StringName)
signal animation_completed(animation_id: StringName)
signal animation_cancelled(animation_id: StringName)

#endregion


#region State

var _profile: HydraAnimationProfile
var _active_tweens: Dictionary[StringName, Tween] = {}

#endregion


#region Lifecycle

func _ready() -> void:
	if _profile == null:
		_profile = HydraAnimationProfile.new()

#endregion


#region Public API

func set_profile(profile: HydraAnimationProfile) -> void:
	assert(profile != null, "Animation profile cannot be null.")
	_profile = profile


func fade_in(
	target: CanvasItem,
	animation_id: StringName
) -> Tween:
	assert(target != null, "Animation target cannot be null.")

	cancel(animation_id)
	target.modulate.a = 0.0
	target.visible = true

	var duration := _get_duration(_profile.standard_duration)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate:a", 1.0, duration)

	return _register_tween(animation_id, tween)


func fade_out(
	target: CanvasItem,
	animation_id: StringName
) -> Tween:
	assert(target != null, "Animation target cannot be null.")

	cancel(animation_id)

	var duration := _get_duration(_profile.standard_duration)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(target, "modulate:a", 0.0, duration)
	tween.tween_callback(target.hide)

	return _register_tween(animation_id, tween)


func slide_in(
	target: Control,
	animation_id: StringName,
	direction: Vector2 = Vector2.LEFT
) -> Tween:
	assert(target != null, "Animation target cannot be null.")

	cancel(animation_id)

	var destination := target.position
	target.position = destination + (
		direction.normalized() * _profile.slide_distance
	)
	target.modulate.a = 0.0
	target.visible = true

	var duration := _get_duration(_profile.standard_duration)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position", destination, duration)
	tween.tween_property(target, "modulate:a", 1.0, duration)

	return _register_tween(animation_id, tween)


func pulse(
	target: CanvasItem,
	animation_id: StringName,
	minimum_alpha: float = 0.45
) -> Tween:
	assert(target != null, "Animation target cannot be null.")

	cancel(animation_id)

	var duration := _get_duration(_profile.slow_duration)
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		target,
		"modulate:a",
		minimum_alpha,
		duration
	)
	tween.tween_property(target, "modulate:a", 1.0, duration)

	return _register_tween(animation_id, tween)


func cancel(animation_id: StringName) -> void:
	if not _active_tweens.has(animation_id):
		return

	var tween := _active_tweens[animation_id]

	if tween != null and tween.is_valid():
		tween.kill()

	_active_tweens.erase(animation_id)
	animation_cancelled.emit(animation_id)


func cancel_all() -> void:
	var animation_ids := _active_tweens.keys()

	for animation_id: StringName in animation_ids:
		cancel(animation_id)

#endregion


#region Private methods

func _register_tween(
	animation_id: StringName,
	tween: Tween
) -> Tween:
	_active_tweens[animation_id] = tween
	animation_started.emit(animation_id)

	tween.finished.connect(
		_on_tween_finished.bind(animation_id),
		CONNECT_ONE_SHOT
	)

	return tween


func _on_tween_finished(animation_id: StringName) -> void:
	_active_tweens.erase(animation_id)
	animation_completed.emit(animation_id)


func _get_duration(configured_duration: float) -> float:
	if _profile.reduced_motion:
		return 0.0

	return configured_duration

#endregion