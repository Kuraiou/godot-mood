@icon("icons/transmission-circle.svg")
@tool
class_name MoodSelector extends MoodMachineChild

## A generic, extensible class for generating and triggering mood transitions
## for a MoodMachine based on child nodes; similar to the way MoodScripts are
## run under Moods, but for picking the next mood.
##
## The structure is mirrored here, as the actual selection mechanism is deferred
## to children, and the selector is itself a machine for evaluating the appropriate
## transition.

enum ProcessMoodOn { IDLE, PHYSICS, MANUAL }
enum ProcessMoodMode {
	# return the first mood from children that is not the current mood.
	FIRST_FOUND,

	# return the most commonly decided-upon mood from children, if it's
	# different from the current mood.
	# If there are multiple most-common moods, return nothing if the current
	# mood is included, otherwise return the first-found mood.
	MOST_COMMON,
	
	# as per most-common, but take the first-found result regardless of whether
	# it is the current mood or not (i.e. prefer node ordering).
	MOST_COMMON_FIRST,

	# as per most-common, but if there are multiple most-common moods, return
	# the first-found one that is NOT the current mood (i.e. prefer switching
	# in case of ties).
	MOST_COMMON_DIFFERENT,
	
	# as per most-common, but do not change mood if there is not consensus
	# amongst children (i.e. more than one "most common" result).
	MOST_COMMON_NO_TIES
}

@export var process_mood_on: ProcessMoodOn = ProcessMoodOn.IDLE:
	set(value):
		if process_mood_on == value:
			return
		
		process_mood_on = value
		
		set_process(value == ProcessMoodOn.IDLE)
		set_physics_process(value == ProcessMoodOn.PHYSICS)

@export var process_mood_mode: ProcessMoodMode = ProcessMoodMode.FIRST_FOUND

#region Built-Ins

func _get_configuration_warnings():
	return super()

## determine the next mood based on the process rules of the child
func _process(_delta):
	if process_mood_on != ProcessMoodOn.IDLE:
		return

	_calc_next_mood()

func _physics_process(_delta):
	if process_mood_on != ProcessMoodOn.PHYSICS:
		return
	
	_calc_next_mood()

func _on_child_entered_tree(node: Node) -> void:
	super(node)
		
#endregion

#region Private Methods

func _calc_next_mood() -> void:
	if Engine.is_editor_hint():
		return
		
	var next_mood: Mood = _find_next_mood()
	if next_mood:
		machine.change_mood(next_mood)

## get the 
func _find_next_mood() -> Mood:
	var found_moods = {}
	var mood_found_order = []
	var max_size = 0

	for child: MoodTransition in find_children("*", "MoodTransition"):
		var next_mood: Mood = child.get_next_mood()

		match process_mood_mode:
			ProcessMoodMode.FIRST_FOUND:
				if machine.current_mood != next_mood:
					return next_mood
			_:
				mood_found_order.append(next_mood)
				if next_mood not in found_moods:
					found_moods[next_mood] = 1
				else:
					found_moods[next_mood] += 1

				if found_moods[next_mood] > max_size:
					max_size = found_moods[next_mood]
	
	var moods = _filter(found_moods, _with_value).keys()
	if len(moods) == 1:
		return moods[0]
	elif process_mood_mode == ProcessMoodMode.MOST_COMMON:
		# if we have ties, we want to return the first one we found as the
		# tie-breaker, which means going through our
		for mood in mood_found_order:
			if mood in moods:
				return mood
		
	return null

## A hash implementation of filter.
func _filter(h: Dictionary, c: Callable) -> Dictionary:
	var n = {}

	for k in h:
		var v = h[k]
		match c.get_argument_count():
			2:
				if c.call(k, v):
					n[k] = v
			1:
				if c.call(v):
					n[k] = v
	
	return n

func _with_value(value: Variant, target: Variant) -> bool:
	return value == target

#endregion
