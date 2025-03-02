@tool
class_name MoodConditionTimeout extends MoodCondition

#region Constants
## put your const vars here.
#endregion

#region Public Variables

@export_range(0.0, 60.0, 1.0, "or_greater") var time_sec := 1.0
@export var process_always := false
@export var process_in_physics := false
@export var ignore_time_scale := false
## If true, this condition is considered *valid* until timeout instead of *invalid*.
@export var start_as_valid := false

#endregion

#region Private Variables
var _timer: SceneTreeTimer
var _valid := false
## put variables you won't touch here, prefixed by an underscore (`var _foo`).
#endregion

#region Signals
## put your signal definitions here.
#endregion

#region Overrides

func _enter_mood(_previous_mood: Mood) -> void:
	_timer = get_tree().create_timer(time_sec, process_always, process_in_physics, ignore_time_scale)
	_valid = start_as_valid
	await _timer.timeout
	_valid = !start_as_valid

func _exit_mood(_next_mood: Mood) -> void:
	_timer = null
	_valid = false

#endregion

#region Public Methods

func is_valid(cache: Dictionary = {}) -> bool:
	return _valid

#endregion

#region Private Methods
## put methods you use only internally here, prefixed with an underscore.
#endregion

#region Signal Hooks
## put methods used as responses to signals here.
## we don't put #endregion here because this is the last block and when we use the
## UI to add signal hooks they always get concatenated at the end of the file.
