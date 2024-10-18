@icon("res://addons/mood/icons/check-circle.svg")
@tool
class_name Mood
extends MoodChild

## A [Mood] is a representation of a State in a [MoodMachine], which is a Finite
## State Machine..
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

#region Signals

## Emitted when the mood is entered.
signal mood_entered(previous_mood: Mood)

## Emitted when the mood is exited.
signal mood_exited(next_mood: Mood)

#endregion

#region Built-In Hooks

func _get_configuration_warnings():
	var errors = super()

	for child in get_children():
		if not child.has_method("_enter_mood"):
			errors.append("The child %s is misconfigured -- it must define `_enter_mood(previous_mood: Mood) -> void`.\nMaybe you should consider using a `MoodScript`?" % child.name)
		if not child.has_method("_exit_mood"):
			errors.append("The child %s is misconfigured -- it must define `_exit_mood(next_mood: Mood) -> void`.\nMaybe you should consider using a `MoodScript`?" % child.name)
		if not "target" in child:
			errors.append("The child %s is misconfigured -- it must have a 'target' property.\nMaybe you should consider using a `MoodScript`?" % child.name)

	return errors

func _enter_tree():
	# by default we want to be disabled, so that the FSM can handle enabling.
	disable()

## when a child comes in under us, if we can assign their mood, let's do so.
func _on_child_entered_tree(node: Node) -> void:
	if "mood" in node:
		node.mood = self

#endregion

#region Overridable Methods

## [b]<OVERRIDABLE>[/b][br][br]
## Called by a [MoodMachine] when the mood is entered.
## Called *before* the signal is emitted and *before* enable() is called.
## [param previous_mood] is the name of the previous [b]StateNode[/b].
@warning_ignore("unused_parameter")
func _enter_mood(previous_mood: Mood) -> void:
	pass

## [b]<OVERRIDABLE>[/b][br][br]
## Called by a [MoodMachine] when the mood is exited.
## [param next_mood] is the name of the next [b]StateNode[/b].
@warning_ignore("unused_parameter")
func _exit_mood(next_mood: Mood) -> void:
	pass

#endregion

#region Public Methods

## Returns [code]true[/code] if the node is the current mood of
## a [MoodMachine].
func is_current_mood() -> bool:
	return machine.current_mood == self

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
