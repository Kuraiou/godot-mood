@tool
## A Mood condition which returns true when the machine's current
## mood is in a whitelisted list of moods. In other words, a mood
## that can only be entered from the whitelisted list of moods.
class_name MoodConditionEntryWhitelist extends MoodCondition

## When entering this mood, trigger _enter_mood on child scripts if the previous mood
## is in this list.
@export var allow_transition_from: Array[Mood] = []

func is_valid(cache: Dictionary = {}) -> bool:
	return machine.current_mood in allow_transition_from
