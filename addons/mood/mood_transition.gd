@tool
@icon("icons/target.svg")
extends MoodMachineChild
class_name MoodTransition

## An abstract parent for evaluating whether or not a transition can be made,
## for use under a [MoodSelector]. Any mechanism which handles transitions
## should 

@export var transition_from: Mood = null:
	set(value):
		transition_from = value
		update_configuration_warnings()
		update_name()

## Scripts to trigger when transitioning 
@export var transition_to: Mood = null:
	set(value):
		transition_to = value
		update_configuration_warnings()
		update_name()

## Update the name automatically to reflect the mood transition for legibility.
func update_name():
	if transition_from and transition_to:
		name = "%sTo%s" % [transition_from.name, transition_to.name]

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
