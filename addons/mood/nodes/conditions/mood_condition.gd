@tool
@icon("res://addons/mood/icons/circle-question.svg")
class_name MoodCondition extends MoodChild

## Return whether or not an input is valid. This must be
## overridden in a child class.
##
## @param cache [Dictionary] an optional cache used to avoid
##   recalculating values across many moods/conditions.
## @return Whether or not the input is valid.
func is_valid(cache: Dictionary = {}) -> bool:
	return false
