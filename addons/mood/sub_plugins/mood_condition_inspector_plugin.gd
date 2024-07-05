@tool
class_name MoodConditionInspectorPlugin extends EditorInspectorPlugin

const COND_GROUP_SCENE: PackedScene = preload("res://addons/mood/inspector_scenes/mood_ui_condition_group.tscn")
const PANEL_SCENE: PackedScene = preload("res://addons/mood/inspector_scenes/mood_ui_group_container.tscn")

var _group_container: VBoxContainer = null

func _can_handle(object: Object) -> bool:
	return object is MoodTransitionProperty

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name != "condition_groups":
		return false

	if object.condition_target:
		var btn := Button.new()
		btn.text = "Add New Condition Group"
		btn.pressed.connect(_add_new_condition_group.bind(object as MoodTransitionProperty))
		add_custom_control(btn)

		_group_container = VBoxContainer.new()

		for condition_group: MoodTransitionConditionGroup in object.condition_groups:
			var scene := COND_GROUP_SCENE.instantiate() as MoodUiConditionGroup
			scene.condition_target = object.condition_target
			scene.remove_group_button.pressed.connect(_on_remove_group_button_pressed.bind(scene, object))
			scene.index_label.text = "%s" % (_group_container.get_child_count() + 1)
			scene.group = condition_group
			var panel = PANEL_SCENE.instantiate()
			panel.add_child(scene)
			_group_container.add_child(panel)

		add_custom_control(_group_container)

	return true # for testing purposes

func _add_new_condition_group(object: MoodTransitionProperty) -> void:
	object.add_condition_group()
	object.notify_property_list_changed()

func _on_remove_group_button_pressed(scene: MoodUiConditionGroup, object: Object) -> void:
	scene.queue_free()
	object.condition_groups.erase(scene.group)
	object.notify_property_list_changed()
