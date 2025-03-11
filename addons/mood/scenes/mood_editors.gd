@tool
class_name MoodEditors extends Object

static var TransitionsContainer: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_transitions_container.tscn")
static var ConditionGroup: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_condition_group.tscn")
static var ConditionProperty: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_condition_property.tscn")
static var ConditionSignal: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_condition_signal.tscn")

static var type_scene_list := {
	"Mood": MoodEditors.TransitionsContainer,
	"MoodTransition": MoodEditors.ConditionGroup,
	"MoodConditionGroup": MoodEditors.ConditionGroup,
	"MoodConditionProperty": MoodEditors.ConditionProperty,
	"MoodConditionSignal": MoodEditors.ConditionSignal,
	#"MoodConditionInput": MoodEditors.ConditionProperty
}

static var field_skips: Dictionary[String, Array] = {
	"Mood": [],
	"MoodConditionGroup": ["and_all_conditions"],
	"MoodTransition": ["and_all_conditions"],
	"MoodConditionProperty": ["property", "comparator", "criteria", "is_callable", "is_node_path", "node_path_root"],
	"MoodConditionSignal": ["signal_triggers"],
	"MoodConditionInput": []
}

static func should_skip_property(node: Node, field: String) -> bool:
	var script_name = node.get_script().get_global_name()
	var skip_fields: Array = field_skips.get(script_name, [])
	var in_field := field in skip_fields
	return in_field

static func has_editor(node: Node) -> bool:
	if not node:
		return false

	var script := node.get_script()
	if not script:
		return false

	var script_name = script.get_global_name()

	return script_name in type_scene_list

# only call after checking with has_editor!
static func get_editor(node: Node) -> CanvasItem:
	var editor_name: StringName = node.get_script().get_global_name()

	if editor_name not in type_scene_list:
		return

	return type_scene_list[editor_name].instantiate()
