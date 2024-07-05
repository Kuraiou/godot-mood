@icon("res://addons/mood/icons/script.svg")

extends MoodScript

@export var print_entry: bool = true
@export var print_exit: bool = true

func _enter_mood(previous_mood: Mood) -> void:
	if print_entry:
		print("Came from %s" % previous_mood.name)

func _exit_mood(next_mood: Mood) -> void:
	if print_exit:
		print("Going to %s" % next_mood.name)
