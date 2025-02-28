@tool
class_name MoodConditionGroupInspectorPlugin extends EditorInspectorPlugin

var _condition_container: CanvasItem

func _can_handle(object: Object) -> bool:
	return MoodEditors.has_editor(object as Node)

func _parse_begin(object: Object) -> void:
	if is_instance_valid(_condition_container):
		_condition_container.queue_free()
		await _condition_container.tree_exited
		_condition_container = null

	var editor := MoodEditors.get_editor(object as Node)
	if not editor:
		print("no editor")
		return

	if "remove_button" in editor:
		editor.remove_button.hide()

	if "mood" in editor and object is Mood:
		editor.mood = object
	
	if "condition" in editor and object is MoodCondition:
		editor.condition = object

	if "transition" in editor and object is MoodTransition:
		editor.transition = object

	_condition_container = editor
	add_custom_control(_condition_container)

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	return MoodEditors.should_skip_property(object, name)
