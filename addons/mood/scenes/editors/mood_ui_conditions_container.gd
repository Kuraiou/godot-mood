@tool
extends VBoxContainer

@export var mood: Mood:
	set(val):
		if mood != null or mood == val: # write once
			return

		mood = val
		_connect_to_mood()
		
		notify_property_list_changed()
		update_configuration_warnings()

#region Public Methods

func add_condition_group(condition_group: MoodConditionGroup) -> void:
	var scene := MoodEditors.ConditionGroup.instantiate()
	scene.index_label.text = condition_group.name
	scene.condition = condition_group

	%Groups.add_child(scene)
	scene.owner = self
	%AddGroupButton.hide()

#endregion

#region Signal Hooks

func _on_remove_group_button_pressed(scene: Node) -> void:
	mood.remove_child(scene.group)
	scene.group.queue_free()
	mood.notify_property_list_changed.call_deferred()
	scene.queue_free()

func _on_add_group_button_pressed() -> void:
	var new_group := MoodConditionGroup.new()
	mood.add_child(new_group)
	new_group.owner = EditorInterface.get_edited_scene_root() # add to real tree
	new_group.name = "Condition Group %s" % (%Groups.get_child_count() + 1)
	add_condition_group(new_group)
	mood.root_condition = new_group

func _on_groups_child_exiting_tree(node: Node) -> void:
	if not node._was_removed:
		return

	var condition_group = node.condition
	await node.tree_exited
	mood.remove_child(condition_group)
	condition_group.queue_free()
	mood.notify_property_list_changed.call_deferred()

	%AddGroupButton.show()

#endregion

#region Private Methods

func _connect_to_mood() -> void:
	var cond := mood.root_condition
	if cond:
		%AddGroupButton.hide()
		add_condition_group(cond)
	else:
		%AddGroupButton.show() # we have a group

#endregion
