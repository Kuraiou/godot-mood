@tool
extends VBoxContainer

#region Public Variables

@export var index_label: Label
@export var _was_removed := false

@export var remove_button: Button

@export var condition: MoodConditionGroup = null:
	set(val):
		if condition != null or condition == val: # write once
			return

		condition = val
		_connect_to_group()

#endregion

#region Public Methods

func add_condition(condition: MoodCondition) -> Node:
	var cond_scene = MoodEditors.get_editor(condition)
	if cond_scene:
		cond_scene.condition = condition
		%Conditions.add_child(cond_scene)

	return cond_scene

#endregion

#region Private Methods

func _create_condition(name_prefix: String, klass: Variant) -> void:
	var child_condition = klass.new()
	child_condition.name = "%s Condition %s" % [name_prefix, len(condition.get_conditions()) + 1]
	condition.add_child(child_condition)
	child_condition.owner = EditorInterface.get_edited_scene_root()
	add_condition(child_condition)
	condition.notify_property_list_changed()

func _connect_to_group() -> void:
	if condition == null:
		return

	index_label.text = condition.name
	%AndAllConditions.button_pressed = condition.and_all_conditions
	condition.renamed.connect(func(): index_label.text = condition.name)

	for cond: MoodCondition in condition.get_conditions():
		add_condition(cond)

#endregion

#region Signal Hooks

# @TODO - popup to pick condition type
func _on_add_condition_pressed() -> void:
	_create_condition("Property", MoodConditionProperty)

func _on_all_of_toggled(toggled_on: bool) -> void:
	condition.and_all_conditions = toggled_on

func _on_remove_group_pressed() -> void:
	_was_removed = true
	queue_free.call_deferred()

func _on_add_signal_condition_pressed() -> void:
	_create_condition("Signal", MoodConditionSignal)

func _on_add_group_condition_button_pressed() -> void:
	_create_condition("Group", MoodConditionGroup)
