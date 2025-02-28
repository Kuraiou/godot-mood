@tool
@icon("res://addons/mood/icons/circles.svg")

## The Finite State Machine for the Mood Plugin.[br]
##
## The MoodMachine should only have [class Mood] nodes as its children. Depending
## on how you configure it, the MoodMachine will continually evaluate the
## [class Mood] children's [class MoodCondition] children to determine which is the
## current valid mood, then enable processing, physics processing, input, and
## unhandled input for all children.[br]
##
## In this way, the "current mood" will be processed as normal by the engine,
## while all other children are, essentially, paused.
class_name MoodMachine extends Node

#region Constants

## used for evaluating the process mode for mood selection.
enum ProcessMoodOn { IDLE, PHYSICS, MANUAL }
## used to determine how to pick which mood to be in.
enum MoodSelectionStrategy {
	# return the first mood from children that is valid.
	FIRST_VALID_MOOD,
	# return the first mood from children that is valid and
	# neither the current nor the previous mood.
	FIRST_VALID_NON_PREVIOUS_MOOD,
	# return the last mood from children that is valid.
	LAST_VALID_MOOD,
	# return the last mood that is from children that are valid
	# and not the previous mood
	LAST_VALID_NON_PREVIOUS_MOOD,
}

## when no moods are valid, the fallback strategy describes
## how to change moods anyways.
enum MoodFallbackStrategy {
	# don't change the mood.
	KEEP_CURRENT_MOOD,
	# re-evaluate previous->current transition. If it's no longer valid, change
	# the mood back to the initial mood
	RE_EVALUATE_AND_FALLBACK_TO_INITIAL,
	# re-evaluate previous->current transition. If it's no longer valid, change
	# the mood back to the initial mood.
	RE_EVALUATE_AND_FALLBACK_TO_PREVIOUS,
	# call the fallback script.
	DEFER_TO_CALLABLE
}

#endregion

#region Public Variables

## The mood to select when the machine is started, before any
## mood condition are evaluated.
## If not set, the first mood child of the machine is used.
@export var initial_mood: Mood = null:
	set(value):
		if initial_mood == value:
			return

		if previous_mood == null:
			previous_mood = initial_mood

		initial_mood = value
		update_configuration_warnings()

## The main object the mood's component scripts will evaluated
## against. Because scripts cannot (currently) be evaluated in
## a dynamic context, the target is used as a reference for evaluating
@export var target: Node = null:
	set(value):
		if target == value:
			return

		target = value
		machine_target_changed.emit(target)
		update_configuration_warnings()

@export_category("Mood Selection Logic")

## See [enum ProcessMoodOn]. When to evaluate which mood is the correct one.
@export var process_mood_on: ProcessMoodOn = ProcessMoodOn.IDLE:
	set(value):
		if process_mood_on == value:
			return

		process_mood_on = value

		set_process(value == ProcessMoodOn.IDLE)
		set_physics_process(value == ProcessMoodOn.PHYSICS)

## See [enum MoodSelectionStrategy]. What strategy to use to handle various
## situations where multiple [class Mood]s might be appropriate.
@export var mood_selection_strategy: MoodSelectionStrategy = MoodSelectionStrategy.FIRST_VALID_MOOD
## See [enum MoodFallbackStrategy]. What strategy to use if no moods are considered valid.
@export var mood_fallback_strategy: MoodFallbackStrategy = MoodFallbackStrategy.KEEP_CURRENT_MOOD
## If the [member mood_fallback_strategy] is MoodFallbackStrategy.DEFER_TO_CALLABLE, this
## is required, and is the script that will be used.[br]
## The script must have this method signature:[br][br]
## 
## [code]_find_next_mood(machine: MoodMachine) -> Mood:[/code]
@export var mood_fallback_script: Script

var _current_mood: Mood = null

## The current mood node reference.
var current_mood: Mood:
	get():
		if _current_mood == null:
			_current_mood = initial_mood

		return _current_mood
	set(value):
		# we must always have a mood.
		if value == null:
			return

		if _current_mood == value:
			return
			
		mood_changing.emit(_current_mood, value)

		if _block_change:
			_block_change = false
			return

		if previous_mood:
			previous_mood.mood_exited.emit(current_mood)
			previous_mood.disable()

		previous_mood = _current_mood
		_current_mood = value
		
		mood_changed.emit(previous_mood, _current_mood)

		value.mood_entered.emit(previous_mood)
		value.enable()

## The previous mood as a node reference.
var previous_mood: Mood = null

#endregion

#region Private Variables

var _block_change: bool = false
var _target: Node

#endregion

#region Signals

## signaled when the target of the machine is changed. Primarily for tool
## scripts and to ensure the consistency of [member target] for all [class MoodChild]
## children.
signal machine_target_changed(target: Node)

## signaled when the mood changes, before the values are
## assigned.
signal mood_changing(current_mood: Mood, next_mood: Mood)

## signaled when the mood has changed, after the new
## value has been assigned.
signal mood_changed(previous_mood: Mood, current_mood: Mood)

#endregion

#region Overrides

## When the machine is ready, it will call [code]_mood_machine_ready[/code]
## on all children which define that method.
func _ready() -> void:
	if target == null:
		target = get_parent()

	Recursion.recurse(self, "_mood_machine_ready")

func _property_can_revert(property: StringName) -> bool:
	return property == &"initial_mood" || property == &"target"

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"initial_mood":
			var children := get_children()
			var idx = children.find_custom(func(node): return node is Mood)
			if idx != -1:
				return children[idx]
			return null
		&"target":
			return get_parent()
		_:
			return null

func _get_configuration_warnings() -> PackedStringArray:
	if initial_mood == null:
		return ["Please add a Mood to this Machine!"]
	return []

## determine the next mood based on the process rules of the child
func _process(_delta) -> void:
	if process_mood_on != ProcessMoodOn.IDLE:
		return

	_calc_next_mood()

func _physics_process(_delta) -> void:
	if process_mood_on != ProcessMoodOn.PHYSICS:
		return

	_calc_next_mood()

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
	var target_mood: Mood

	if mood is Mood:
		target_mood = mood
	elif mood is String:
		target_mood = find_child(mood, false)

	if target_mood:
		current_mood = target_mood
	else:
		push_error("Attempted to go to mood %s but it is not a child mood of %s" % [mood, name])

#endregion

#region Private Methods

func _calc_next_mood() -> void:
	if Engine.is_editor_hint():
		return

	var next_mood: Mood = _find_next_mood()
	if next_mood:
		change_mood(next_mood)

## get the
func _find_next_mood() -> Mood:
	var transitions := current_mood.find_children("*", "MoodTransition", false) as Array[MoodTransition]

	match mood_selection_strategy:
		MoodSelectionStrategy.FIRST_VALID_MOOD:
			for transition: MoodTransition in transitions:
				if transition.is_valid():
					return transition.to_mood

		MoodSelectionStrategy.FIRST_VALID_NON_PREVIOUS_MOOD:
			for transition: MoodTransition in transitions:
				if transition.to_mood == previous_mood:
					continue

				if transition.is_valid():
					return transition.to_mood

		MoodSelectionStrategy.LAST_VALID_MOOD:
			transitions.reverse()
			for transition: MoodTransition in transitions:
				if transition.is_valid():
					return transition.to_mood

		MoodSelectionStrategy.LAST_VALID_NON_PREVIOUS_MOOD:
			transitions.reverse()
			for transition: MoodTransition in transitions:
				if transition.to_mood == previous_mood:
					continue

				if transition.is_valid():
					return transition.to_mood

	match mood_fallback_strategy:
		MoodFallbackStrategy.KEEP_CURRENT_MOOD:
			pass
		MoodFallbackStrategy.RE_EVALUATE_AND_FALLBACK_TO_INITIAL:
			for transition_node: MoodTransition in (previous_mood.find_children("*", "MoodTransition", false) as Array[MoodTransition]):
				if transition_node.to_mood == current_mood:
					if !transition_node.is_valid():
						return initial_mood
					break
		MoodFallbackStrategy.RE_EVALUATE_AND_FALLBACK_TO_PREVIOUS:
			for transition_node: MoodTransition in (previous_mood.find_children("*", "MoodTransition", false) as Array[MoodTransition]):
				if transition_node.to_mood == current_mood:
					if !transition_node.is_valid():
						return previous_mood
					break
		MoodFallbackStrategy.DEFER_TO_CALLABLE:
			if mood_fallback_script and mood_fallback_script.can_instantiate():
				var instance = Object.new()
				instance.set_script(mood_fallback_script)
				return instance._find_next_mood(self)

	return current_mood

#endregion

#region Signal Hooks
