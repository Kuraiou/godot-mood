@tool
class_name MoodTransitionSignalInspectorPlugin extends EditorInspectorPlugin

const SIGNAL_SCENE: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_signal_transition.tscn")

var _container: Control

func _can_handle(object: Object) -> bool:
	return object is MoodTransitionSignal

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name != "signal_triggers":
		return false

	if object.signal_target == null:
		return true

	if is_instance_valid(_container):
		_container.queue_free()
		await _container.tree_exited
		_container = null

	_container = SIGNAL_SCENE.instantiate()
	_container.transition = object
	add_custom_control(_container)

	return true
