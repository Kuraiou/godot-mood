@tool
class_name MoodEditors extends Object

static var ConditionsContainer: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_conditions_container.tscn")
static var ConditionGroup: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_condition_group.tscn")
static var ConditionProperty: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_condition_property.tscn")
static var ConditionSignal: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_condition_signal.tscn")

static var type_scene_list := {
	"Mood": MoodEditors.ConditionsContainer,
	"MoodConditionGroup": MoodEditors.ConditionGroup,
	"MoodConditionProperty": MoodEditors.ConditionProperty,
	"MoodConditionSignal": MoodEditors.ConditionSignal
}

static var field_skips: Dictionary[String, Array] = {
	"Mood": [],
	"MoodConditionGroup": ["and_all_conditions"],
	"MoodConditionProperty": ["property", "comparator", "criteria", "is_callable"],
	"MoodConditionSignal": ["signal_triggers"]
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

	return script.get_global_name() in type_scene_list

# only call after checking with has_editor!
static func get_editor(node: Node) -> CanvasItem:
	var editor_name: StringName = node.get_script().get_global_name()

	return type_scene_list[editor_name].instantiate()
