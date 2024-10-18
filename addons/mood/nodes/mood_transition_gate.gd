@icon("icons/filter.svg")
@tool
class_name MoodTransitionGate extends MoodChild

## A Conditional Logic node which evaluates whether or not the transition came from
## a whitelisted previous mood (for [_enter_mood]) or next mood (for [_exit_mood]),
## and if so calls the appropriate method on the children moods.

## When entering this mood, trigger _enter_mood on child scripts if the previous mood
## is in this list.
@export var on_transition_from: Array[Mood] = []:
	set(value):
		on_transition_from = value
		update_configuration_warnings()


## When exiting this mood, trigger _exit_mood on child scripts of the next mood
## is in this list.
@export var on_transition_to: Array[Mood] = []:
	set(value):
		on_transition_to = value
		update_configuration_warnings()

func _init():
	super()
		
func _get_configuration_warnings():
	var errors = super()
	
	for from_node: Mood in on_transition_from:
		if from_node.mood.machine != mood.machine:
			errors.append("Attempting to track transition from %s, but its parent mood, %s, belongs to a different machine" % [from_node.name, from_node.mood.name])
	
	for to_node: Mood in on_transition_to:
		if to_node.mood.machine != mood.machine:
			errors.append("Attempting to track transition from %s, but its parent mood, %s, belongs to a different machine" % [to_node.name, to_node.mood.name])
	
	return errors

## If we're entering from a mood that we've whitelisted, run _enter_mood on all children.
## Otherwise, do nothing.
func _enter_mood(previous_mood: Mood) -> void:
	if not on_transition_from.has(previous_mood):
		return
	
	for child in get_children():
		child._enter_mood(previous_mood)

## If we're exiting to a mood that we've whitelisted, run _exit_mood on all children.
## Otherwise, do nothing.
func _exit_mood(next_mood: Mood) -> void:
	if not on_transition_to.has(next_mood):
		return
	
	for child in get_children():
		child._exit_mood(next_mood)
