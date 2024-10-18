@tool
@icon("res://addons/mood/icons/target.svg")
class_name MoodTransition
extends MoodMachineChild

## An abstract parent for evaluating whether or not a transition can be made,
## for use under a [MoodSelector]. Any mechanism which handles transitions
## should 

@export var transition_from: Mood = null:
	set(value):
		if transition_from and transition_from.name_changed.is_connected(update_name):
			transition_from.name_changed.disconnect(update_name)

		transition_from = value

		if transition_from == null:
			queue_free()
			return

		transition_from.name_changed.connect(update_name)
		update_configuration_warnings()
		update_name()

## Scripts to trigger when transitioning 
@export var transition_to: Mood = null:
	set(value):
		if transition_to and transition_to.name_changed.is_connected(update_name):
			transition_to.name_changed.disconnect(update_name)

		transition_to = value

		if transition_to == null:
			queue_free()
			return

		transition_to.name_changed.connect(update_name)
		update_configuration_warnings()
		update_name()

var _overridden_name := false

## Update the name automatically to reflect the mood transition for legibility.
func update_name():
	if _overridden_name:
		return

	if transition_from and transition_to:
		name = "%sTo%s" % [transition_from.name, transition_to.name]

func set_name(value: String) -> void:
	if name == value:
		return

	if !(is_instance_valid(transition_from) && is_instance_valid(transition_to)):
		_overridden_name = true
		name = value
		return
	
	var calced_name = "%sTo%s" % [transition_from.name, transition_to.name]
	_overridden_name = value != calced_name
	super(value)

func _get_configuration_warnings():
	var errors = super()
	
	if transition_from and transition_from.machine != machine:
		errors.append("Attempting to track transition from %s, but its parent mood, %s, belongs to a different machine" % [transition_from.name, transition_from.mood.name])
	
	if transition_to and transition_to.machine != machine:
		errors.append("Attempting to track transition from %s, but its parent mood, %s, belongs to a different machine" % [transition_to.name, transition_to.mood.name])
	
	return errors

## The function that needs to be overridden in child transition classes to evaluate
## appropriate conditioning.
func get_next_mood() -> Mood:
	if machine.current_mood == transition_from and _is_valid():
		return transition_to
	return null

## this function MUST be overridden by child classes to return true to enable
## transitioning!
func _is_valid() -> bool:
	return false
