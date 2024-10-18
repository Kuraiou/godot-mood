@tool
class_name MoodUiConditionGroup extends VBoxContainer

const CONDITION_SCENE: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_condition.tscn")

#region Public Variables

@export var index_label: Label
@export var _was_removed := false

@export var condition_target: Node:
	set(val):
		if condition_target == val:
			return

		condition_target = val

@export var group: MoodConditionGroup = null:
	set(val):
		if group != null or group == val: # write once
			return

		group = val
		
		_connect_to_group()

#endregion

#region Public Methods

func add_condition(condition: MoodCondition, id: int = -1) -> Node:
	if id == -1:
		id = %Conditions.get_child_count()

	var cond_scene = CONDITION_SCENE.instantiate() as MoodUiCondition

	cond_scene.condition_target = condition_target
	cond_scene.condition = condition
	cond_scene.index_label.text = "%s" % (id + 1)

	if id == 0: # this is our first/only condition so let's hide it.
		cond_scene.remove_condition_button.hide()

	%Conditions.add_child(cond_scene)

	return cond_scene

#region Signal Hooks

func _on_add_condition_pressed() -> void:
	if %Conditions.get_child_count() == 1: # we're adding our second entry so show the remove button on the first
		%Conditions.get_child(0).remove_condition_button.show()

	var new_condition := MoodCondition.new()
	group.conditions.append(new_condition)
	group.notify_property_list_changed()
	add_condition(new_condition)

func _on_all_of_toggled(toggled_on: bool) -> void:
	group.and_all_conditions = toggled_on

func _on_remove_group_pressed() -> void:
	_was_removed = true
	queue_free.call_deferred()

func _on_conditions_child_exiting_tree(node: Node) -> void:
	if not node._was_removed:
		return

	var condition: MoodCondition = node.condition
	await node.tree_exited

	group.conditions.erase(condition)
	group.notify_property_list_changed()

	match %Conditions.get_child_count():
		0:
			_on_add_condition_pressed()
			return # return so we don't double-notify below
		1:
			%Conditions.get_child(0).remove_condition_button.hide()

	var id := 1
	for scene in %Conditions.get_children():
		scene.index_label.text = "%s" % id
		id += 1

#endregion

#region Private Methods

func _connect_to_group() -> void:
	if not is_node_ready():
		await ready

	%AndAllConditions.button_pressed = group.and_all_conditions

	for cond: MoodCondition in group.conditions:
		add_condition(cond)

#endregion
