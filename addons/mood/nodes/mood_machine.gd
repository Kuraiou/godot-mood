@icon("res://addons/mood/icons/circles.svg")
@tool
class_name MoodMachine extends Node

## A node used to manage and process logic on [Mood] children.

#region Configuration (Exports)

## The mood to select when the machine is started, before any
## mood condition are evaluated.
## If not set, the first mood child of the machine is used.
@export var initial_mood: Mood = null:
	get():
		if initial_mood:
			return initial_mood

		return find_children("*", "Mood").front() as Mood

## The main object the mood's component scripts will evaluate
## against. Because scripts cannot (currently) be evaluated in
## a dynamic context, the target is used as a reference for evaluating
##
@export var target: Node = null:
	set(value):
		# pass the target through to moods and underlying components.
		for child in get_children():
			if "target" in child:
				child.target = value

		if target == value:
			return
		
		target = value

#endregion

#region Member Attributes

## The current mood node reference.
var current_mood: Mood = null:
	get():
		if current_mood:
			return current_mood
		return initial_mood
	set(value):
		# we must always have a mood.
		if value == null:
			return

		if current_mood == value:
			return
			
		mood_changing.emit(current_mood, value)

		if _block_change:
			_block_change = false
			return

		if previous_mood:
			previous_mood._exit_mood(current_mood)
			previous_mood.mood_exited.emit(current_mood)
			previous_mood.disable()

		previous_mood = current_mood
		current_mood = value
		
		mood_changed.emit(previous_mood, current_mood)

		value._enter_mood(previous_mood)
		value.mood_entered.emit(previous_mood)
		value.enable()

var previous_mood: Mood = null
var _block_change: bool = false

#endregion

#region Signals

## A tool signal for when a mood is added or removed.
signal mood_list_changed(mood_mode: Mood)

## signaled when the mood changes, before the values are
## assigned.
signal mood_changing(current_mood: Mood, next_mood: Mood)

## signaled when the mood has changed, after the new
## value has been assigned.
signal mood_changed(previous_mood: Mood, current_mood: Mood)

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

## If an underlying script wants to stop a transition, it can call
## this method in response to the mood_changed signal.
func keep_mood() -> void:
	_block_change = true

## Change the current mood manually.
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

#endregion

#region Signal Response Methods

func _on_child_entered_tree(child: Node) -> void:
	if "machine" in child:
		child.machine = self

	if child is Mood and is_node_ready():
		mood_list_changed.emit(child)

## When a child [Mood] node leaves the FSM, we want to reflect that change onto
## the editor graph, so we need to emit the mood list changed signal.
func _on_child_exiting_tree(child: Node) -> void:
	await child.tree_exited

	if "machine" in child and is_instance_valid(child):
		# @NEEDS_TEST: moving a child from one machine to another, does it
		# reassign properly?
		child.machine = null

#endregion

#region Private Methods

## From top down, call [_mood_machine_ready] on children.
func _recursively_ready_children(child: Node) -> void:
	if child.has_method("_mood_machine_ready"):
		child._mood_machine_ready()

	for grandchild in child.get_children():
		_recursively_ready_children(grandchild)

#endregion
