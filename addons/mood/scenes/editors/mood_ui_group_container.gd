@tool
class_name MoodUiGroupContainer extends VBoxContainer

const COND_GROUP_SCENE: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_condition_group.tscn")

@export var transition: MoodTransitionProperty:
	set(val):
		if transition != null or transition == val: # write once
			return

		transition = val
		_connect_to_transition()
		
		notify_property_list_changed()
		update_configuration_warnings()

#region Public Methods

func add_condition_group(condition_group: MoodTransitionConditionGroup, id: int = -1) -> void:
		if id == -1:
			id = %Groups.get_child_count()

		var scene := COND_GROUP_SCENE.instantiate() as MoodUiConditionGroup
		scene.condition_target = transition.condition_target
		scene.index_label.text = "%s" % (id + 1)
		scene.group = condition_group

		%Groups.add_child(scene)
		scene.owner = self

#endregion

#region Signal Hooks

func _on_remove_group_button_pressed(scene: MoodUiConditionGroup) -> void:
	transition.condition_groups.erase(scene.group)
	transition.notify_property_list_changed()
	scene.queue_free()

func _on_add_group_button_pressed() -> void:
	var new_group := MoodTransitionConditionGroup.new()
	new_group.conditions = [MoodTransitionCondition.new()] as Array[MoodTransitionCondition]
	transition.condition_groups.append(new_group)
	add_condition_group(new_group)

func _on_groups_child_exiting_tree(node: Node) -> void:
	if not node._was_removed:
		return

	var condition_group = node.group
	await node.tree_exited
	transition.condition_groups.erase(condition_group)
	transition.notify_property_list_changed()

	var id := 1
	for scene in %Groups.get_children():
		scene.index_label.text = "%s" % id
		id += 1

#endregion

#region Private Methods

func _connect_to_transition() -> void:
	if not is_node_ready():
		await ready

	var id := 0
	for condition_group: MoodTransitionConditionGroup in transition.condition_groups:
		add_condition_group(condition_group, id)
		id += 1

#endregion
