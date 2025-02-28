@tool

## A generic class for handling all of the children of a finite state machine
## so that target state and process type/state changes are propagated down to
## any leaves, making it easy for us to avoid having to fetch values dynamically
## inside of looping (e.g. process) calls.
class_name MoodMachineChild extends Node

#region Public Variables

var _machine: MoodMachine = null

## The parent machine.
var machine: MoodMachine:
	get():
		if _machine == null:
			machine = Recursion.find_parent(self, MoodMachine)

		return _machine
	set(val):
		if _machine == val:
			return

		if _machine:
			if _machine.machine_target_changed.is_connected(_on_machine_target_changed):
				_machine.machine_target_changed.disconnect(_on_machine_target_changed)

		_machine = val

		if _machine:
			_machine.machine_target_changed.connect(_on_machine_target_changed)
			_target = _machine.target
		else:
			_target = null

var _target: Node = null

## The referent for this script's operation, inherited from the parent Machine.
## see: [method MoodMachine.target]
var target: Node:
	get():
		if _target == null:
			_target = machine.target
		return _target
	set(val):
		if _target == val:
			return
		_target = val
		notify_property_list_changed()

#endregion

#region Overrides

func _get_configuration_warnings() -> PackedStringArray:
	var transition_targets := {} as Dictionary[String, bool]
	var errors := [] as PackedStringArray

	for transition: Node in find_children("*", "MoodTransition", false):
		if not is_instance_valid(transition.to_mood):
			continue

		var transition_to := transition.to_mood.name as String
		if transition_targets.get(transition_to, false):
			errors.append("%s has multiple Transitions to it, behavior may be unexpected." % transition_to)
		else:
			transition_targets[transition_to] = true
	
	return errors

#endregion

#region Private Methods

## [b]<OVERRIDABLE>[/b][br][br]
## Called by a [MoodMachine] once it is ready. Use it when a state needs to
## interact with one or more of its sibling states.
func _mood_machine_ready() -> void:
	pass

#endregion

#region Signal Hooks

func _on_machine_target_changed(new_target: Node) -> void:
	target = new_target
