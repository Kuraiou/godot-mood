@tool
class_name MoodConditionTimeout extends MoodCondition

## A condition which is valid based on a triggered timeout that begins when
## the parent mood is entered, so you can e.g. set up a condition that allows
## for transition to another node if an action is taken within N seconds of
## entry (if [member start_as_valid] is [code]true[/code]) or after N seconds
## (if [member start_as_valid] is [code]false[/code]).

#region Constants

## Controls how we treat validity relative to the timeout.
enum ValidationMode {
	## Become valid on mood entry, become invalid on mood exit or timeout.
	VALID_ON_ENTRY,
	## Become valid on mood exit, become invalid on mood entry or timeout.
	VALID_ON_EXIT,
	## Become valid on mood entry until timeout.
	VALID_ON_ENTRY_UNBOUND,
	## Become valid on mood exit until timeout.
	VALID_ON_EXIT_UNBOUND 
}

#region Public Variables

## Whether or not you want validity on mood entry or exit, and whether or not you want
## to invalidate on mood entry or exit (typically when [member MoodMachine.evaluate_nodes_directly]
## is [code]true[/code]) or only timeout (typically when false).
@export var validation_mode := ValidationMode.VALID_ON_ENTRY
## If using an UNBOUND validation mode, whether or not we want to reset the
## timer when re-triggering validity, or just leave it alone.
@export var reset_on_reentry := true

@export_group("Timer Settings")
## How long between when this condition becomes valid and the timeout occurs. 
@export_range(0.0, 60.0, 1.0, "or_greater") var time_sec := 1.0
## passthrough for [member SceneTree.create_timer] [param process_always].
@export var process_always := false
## passthrough for [member SceneTree.create_timer] [param process_in_physics].
@export var process_in_physics := false
## passthrough for [member SceneTree.create_timer] [param ignore_time_scale].
@export var ignore_time_scale := false

#endregion

#region Private Variables

var _timer: SceneTreeTimer
var _valid := false

#endregion

#region Overrides

## Validity is reset when the parent mood is entered.
func _enter_mood(_previous_mood: Mood) -> void:
	match validation_mode:
		ValidationMode.VALID_ON_ENTRY, ValidationMode.VALID_ON_ENTRY_UNBOUND:
			_make_valid()
		ValidationMode.VALID_ON_EXIT:
			_on_timer_timeout()

## When we leave this mood, we are never valid.
func _exit_mood(_next_mood: Mood) -> void:
	match validation_mode:
		ValidationMode.VALID_ON_EXIT, ValidationMode.VALID_ON_EXIT_UNBOUND:
			_make_valid()
		ValidationMode.VALID_ON_ENTRY:
			_on_timer_timeout()

#endregion

#region Public Methods

func is_valid(cache: Dictionary = {}) -> bool:
	return _valid

#endregion

#region Private Methods

## Trigger the timer and set self as _valid.
func _make_valid() -> void:
	if is_instance_valid(_timer):
		if reset_on_reentry:
			if _timer.timeout.is_connected(_on_timer_timeout):
				_timer.timeout.disconnect(_on_timer_timeout)
			_timer = get_tree().create_timer(time_sec, process_always, process_in_physics, ignore_time_scale)
	_valid = true

## put methods you use only internally here, prefixed with an underscore.
#endregion

#region Signal Hooks

## When we time out the timer we our never considered valid at that point.
func _on_timer_timeout() -> void:
	if is_instance_valid(_timer):
		_timer.timeout.disconnect(_on_timer_timeout)
	_valid = false
	_timer = null
