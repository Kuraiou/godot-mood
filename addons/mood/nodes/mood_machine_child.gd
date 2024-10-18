@tool
extends Node
class_name MoodMachineChild

## A generic class for handling all of the children of a finite state machine
## so that target state and process type/state changes are propagated down to
## any leaves, making it easy for us to avoid having to fetch values dynamically
## inside of looping (e.g. process) calls.

## The target. Do not directly set this value on an Mood; it should only be set
## by updating the target of the parent MoodMachine or by setting [param target_node_override]
## to the node and setting [param override_parent_target] to true.
var target: Node = null:
	set(value):
		for child in get_children():
			if "target" in child:
				child.target = value

		if target == value:
			return
		
		target = value

## The parent machine.
var machine: MoodMachine:
	set(value):
		for child in get_children():
			if "machine" in child:
				child.machine = value

		if machine == value:
			return

		machine = value

		if machine and not target:
			target = machine.target

#region Built-Ins

func _get_configuration_warnings():
	var errors = []
	var parent = get_parent()
	if not (parent is MoodMachine or parent is MoodMachineChild):
		errors.append("The parent of a Mood should be a MoodMachine or another FSM child.")

	return errors

func _init() -> void:
	child_entered_tree.connect(_on_child_entered_tree)

func _on_child_entered_tree(node: Node) -> void:
	if "machine" in node:
		node.machine = machine

#endregion

## [b]<OVERRIDABLE>[/b][br][br]
## Called by a [MoodMachine] once it is ready. Use it when a state needs to
## interact with one or more of its sibling states.
@warning_ignore("unused_parameter")
func _mood_machine_ready() -> void:
	pass
