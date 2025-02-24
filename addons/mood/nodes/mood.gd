@tool
@icon("res://addons/mood/icons/target.svg")

class_name Mood extends MoodMachineChild

## A [Mood] is a representation of a State in a [MoodMachine], which is a Finite
## State Machine.
##
## * the parent of a Mood must be a MoodMachine or else warning will be raised.
## * all Mood children of a given MoodMachine have different names.
## * the children of an Mood must be MoodChild nodes or a warning will be raised.
## * the system uses the built-in _process, _physics_process, _input, etc. of any node.
## * the target of an MoodMachine (and thus Mood) is a parent up the tree
##   of the machine and thus if the machine is running the target is valid.
##
## For the code to be performant (well, as performant as is possible in GDScript) and fast it
## assumes that the above rules are always true.
##
## When a target is assigned to an Mood, that target will propagate down explicitly to
## all of its child MoodScripts immediately.

#region Public Variables

## the root condition for evaluating whether you should be in this mood.
## If this is not explicitly set, will return the first [MoodCondition] child
## (meaning multiple condition children will not do anything).
var _root_condition: MoodCondition
@export var root_condition: MoodCondition:
	get():
		if _root_condition == null:
			var children := get_children()
			var idx = children.find_custom(func (child): return child is MoodCondition)
			if idx != -1:
				_root_condition = children[idx]

		return _root_condition
	set(value):
		if _root_condition == value:
			return

		_root_condition = value
		notify_property_list_changed()

#endregion

#region Signals

## Emitted when the mood is entered.
signal mood_entered(previous_mood: Mood)

## Emitted when the mood is exited.
signal mood_exited(next_mood: Mood)

#endregion

#region Overrides

func _enter_tree() -> void:
	if machine.initial_mood == null:
		machine.initial_mood = self
	# by default we want to be disabled, so that the FSM can handle enabling.
	disable()

#endregion

#region Public Methods

## Returns [code]true[/code] if the node is the current mood of
## a [MoodMachine].
func is_current_mood() -> bool:
	return machine.current_mood == self

## Returns [code]true[/code] if all child [[MoodCondition]] nodes return
## true for [[MoodCondition#_is_valid]].
func is_valid() -> bool:
	if not is_instance_valid(root_condition):
		return false

	var cache := {}
	return root_condition.is_valid(cache)

## Turn on processing for oneself and one's children.
func enable() -> void:
	Recursion.recurse(self, "set_process", true)
	Recursion.recurse(self, "set_physics_process", true)
	Recursion.recurse(self, "set_process_input", true)
	Recursion.recurse(self, "set_process_unhandled_input", true)

## Turn off processing for oneself and one's children.
func disable() -> void:
	Recursion.recurse(self, "set_process", false)
	Recursion.recurse(self, "set_physics_process", false)
	Recursion.recurse(self, "set_process_input", false)
	Recursion.recurse(self, "set_process_unhandled_input", false)

#endregion

#region Signal Hooks
