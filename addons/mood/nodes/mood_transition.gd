@icon("res://addons/mood/icons/circle-arrow-right.svg")
@tool
class_name MoodTransition extends MoodConditionGroup

## A class which represents the root of condition nodes to transition to a
## specific mood.

#region Constants
## put your const vars here.
#endregion

#region Public Variables

@export var to_mood: Mood:
	set(val):
		if to_mood == val:
			return
		
		to_mood = val
		notify_property_list_changed()
		update_configuration_warnings()

#endregion

#region Private Variables
## put variables you won't touch here, prefixed by an underscore (`var _foo`).
#endregion

#region Signals
## put your signal definitions here.
#endregion

#region Overrides

func _get_configuration_warnings() -> PackedStringArray:
	var results := []
	
	if !is_instance_of(get_parent(), Mood):
		results.append("The MoodTransition must be a child of a Mood.")

	if is_instance_valid(to_mood):
		if to_mood == get_parent():
			results.append("You cannot transition a mood to itself.")

		if to_mood.machine != (get_parent() as Mood).machine:
			results.append("The target mood must be in the same MoodMachine as this mood.")
	
	return results

## virtual override methods here, e.g.
## _init, _ready
## _process, _physics_process
## _enter_tree, _exit_tree
#endregion

#region Public Methods
## put your methods here.
#endregion

#region Private Methods
## put methods you use only internally here, prefixed with an underscore.
#endregion

#region Signal Hooks
## put methods used as responses to signals here.
## we don't put #endregion here because this is the last block and when we use the
## UI to add signal hooks they always get concatenated at the end of the file.
