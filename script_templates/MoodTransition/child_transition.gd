@icon("res://addons/mood/icons/circle-arrow.svg")
# meta-name: Mood Transition
# meta-description: A class which evaluates whether or not we can transition between moods.
# meta-default: true
# meta-space-indent: 4
# meta-icon: "res://addons/mood/icons/circle-arrow.svg"

extends MoodTransition

# Override this function to provide your evaluation logic.
func _is_valid() -> bool:
	return true
