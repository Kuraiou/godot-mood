@icon("res://addons/mood/icons/circles.svg")
@tool
class_name MoodMachine extends Node

## A node used to manage and process logic on [Mood] children.

#region Configuration

@export var initial_mood: Mood = null:
	set(value):
		initial_mood = value
		update_configuration_warnings()

@export var target: Node = null:
	set(value):
		for child in get_children():
			if child is MoodMachineChild:
				child.target = value

		if target == value:
			return
		
		target = value

#endregion

#region Member Attributes

var current_mood: Mood = null:
	set(value):
		if value == null:
			return

		if current_mood == value:
			return

		if previous_mood:
			previous_mood._exit_mood(current_mood)
			previous_mood.mood_exited.emit(current_mood)
			previous_mood.disable()
		previous_mood = current_mood

		value._enter_mood(previous_mood)
		value.mood_entered.emit(previous_mood)
		value.enable()

		current_mood = value
		mood_changed.emit(previous_mood, current_mood)

var previous_mood: Mood = null

#endregion

#region Signals

## A tool signal for when a mood is added or removed.
signal mood_list_changed(mood_mode: Mood)

## signaled when the mood changes.
signal mood_changed(previous_mood: Mood, next_mood: Mood)

#endregion

#region Built-In Hooks

func _init():
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)

func _ready() -> void:
	for child in get_children():
		_recursively_ready_children(child)
	
	# this will enable the initial mood and its scripts.
	current_mood = initial_mood

#endregion

#region Public Methods

## Return the current mood as a name.
func mood() -> String:
	return current_mood.name

## Change the current mood.
## @param mood [String, Mood] the mood to change to.
## @return [Error] OK if the node was found, 
func change_mood(mood: Variant) -> void:
	var mood_mode: Mood

	if mood is Mood:
		mood_mode = mood
		if mood_mode.machine != self:
			push_error("Attempted to change mood for machine %s to a mood that belongs to machine %s" % [name, mood_mode.machine.name])
			return
	elif mood is String:
		mood_mode = find_child(mood, false)

	if mood_mode:
		current_mood = mood_mode
	else:
		push_error("Attempted to go to mood %s but it is not a child mood of %s" % [mood, name])

func reset_changes() -> void:
	var did_changes := false
	if has_meta("_graph_new_moods"):
		did_changes = true
		remove_meta("_graph_new_moods")

	for child: Mood in find_children("*", "Mood") as Array[Mood]:
		if child.has_unsaved_changes():
			did_changes = true
			child.reset_changes(false)

	if did_changes:
		mood_list_changed.emit(null)
		notify_property_list_changed()

#endregion

#region Built-In Overloads

#func set_meta(meta_name: StringName, value: Variant) -> void:
	#super(meta_name, value)
#
#func remove_meta(meta_name: StringName) -> void:
	#super(meta_name)

#endregion

#region Signal Response Methods

func _on_child_entered_tree(child: Node) -> void:
	if child is MoodMachineChild:
		child.machine = self

		if child is Mood:
			var name_callable = _on_child_mood_changed_name.bind(child)
			if not child.name_changed.is_connected(name_callable):
				child.name_changed.connect(name_callable)
	
			# if we're not ready then we're just rebuilding, that's not the same.
			if is_node_ready():
				mood_list_changed.emit(child)

		update_configuration_warnings()

## When a child [Mood] node leaves the FSM, we want to reflect that change onto
## the editor graph, so we need to emit the mood list changed signal.
func _on_child_exiting_tree(child: Node) -> void:
	await child.tree_exited

	if "machine" in child:
		# @NEEDS_TEST: moving a child from one machine to another, does it
		# reassign properly?
		child.machine = null
		update_configuration_warnings()

## When a child [Mood] node changes it's name, we want to reflect that change
## onto the editor graph, so we need to emit the mood list changed signal.
func _on_child_mood_changed_name(old_name: StringName, mood_mode: Mood) -> void:
	# only emit if the name change isn't just the adding a "*":
	if old_name.rstrip("*") != mood_mode.name.rstrip("*"):
		mood_list_changed.emit(mood_mode)

#endregion

#region Private Methods

## From top down, call [_mood_machine_ready] on children.
func _recursively_ready_children(child: Node) -> void:
	if child.has_method("_mood_machine_ready"):
		child._mood_machine_ready()

	for grandchild in child.get_children():
		_recursively_ready_children(grandchild)

#endregion
