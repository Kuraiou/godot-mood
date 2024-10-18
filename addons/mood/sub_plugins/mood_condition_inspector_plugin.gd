@tool
class_name MoodConditionInspectorPlugin extends EditorInspectorPlugin

const COND_GROUP_CONTAINER_SCENE: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_group_container.tscn")
const PANEL_SCENE: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_group_container.tscn")

var _group_container: MoodUiGroupContainer

func _can_handle(object: Object) -> bool:
	return object is MoodTransitionProperty

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name != "condition_groups":
		return false

	if is_instance_valid(_group_container):
		_group_container.queue_free()
		await _group_container.tree_exited
		_group_container = null

	_group_container = COND_GROUP_CONTAINER_SCENE.instantiate() as MoodUiGroupContainer
	_group_container.transition = object

	add_custom_control(_group_container)

	return true # for testing purposes
