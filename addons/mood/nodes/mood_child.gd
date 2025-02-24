@tool

## Any function which conditionally operates or responds to changes in mood
## should go under the Mood representing that mood; the [MoodChild] class
## acts as a simple wrapper around that behavior.
## Note that Moods can have a parent that is a Mood itself to perform
## combination behaviors.
class_name MoodChild extends MoodMachineChild

#region Public Variables

var _mood: Mood = null

## The [class Mood] that acts as the fundamental parent mood.
## Because a [class Mood] is itself a [class MoodChild], it can have a parent
## mood that is different from itself; this allows for complex multi-mood
## assignment, or at least, ideally it will.
var mood: Mood:
	get():
		if _mood == null:
			mood = Recursion.find_parent(self, Mood)
		return _mood
	set(value):
		if _mood == value:
			return

		if _mood:
			if has_method("_enter_mood"):
				var em := Callable(self, "_enter_mood")
				if _mood.mood_entered.is_connected(em):
					_mood.mood_entered.disconnect(em)
			if has_method("_exit_mood"):
				var em := Callable(self, "_exit_mood")
				if _mood.mood_exited.is_connected(em):
					_mood.mood_exited.disconnect(em)
		
		_mood = value

		if _mood:
			if has_method("_enter_mood"):
				var em := Callable(self, "_enter_mood")
				if not _mood.mood_entered.is_connected(em):
					_mood.mood_entered.connect(em)
			if has_method("_exit_mood"):
				var em := Callable(self, "_exit_mood")
				if not _mood.mood_exited.is_connected(em):
					_mood.mood_exited.connect(em)

		# assign our processing status to match the mood's.
		set_process(_mood.is_processing())
		set_physics_process(_mood.is_physics_processing())
		set_process_input(_mood.is_processing_input())
		set_process_unhandled_input(_mood.is_processing_unhandled_input())

		update_configuration_warnings()

#endregion

#region Overrides
#endregion

#region Signal Hooks
