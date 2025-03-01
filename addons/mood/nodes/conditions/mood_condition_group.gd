@tool
@icon("res://addons/mood/icons/transmission-circle.svg")
class_name MoodConditionGroup extends MoodCondition

## A Condition used to group multiple conditions together.

#region Public Variables

## If this is true, then the condition group evaluates to true only if
## all of the conditions evaluate to true (bitwise "and"). Otherwise, the
## condition evaluates to true if _any_ of the conditions evaluate to true
## (bitwise "OR").
@export var and_all_conditions: bool = true

#endregion

#region Overrides
#endregion

#region Public Methods

var _conditions: Array[MoodCondition]
func get_conditions(use_cache: bool = true) -> Array[MoodCondition]:
	use_cache = use_cache and !Engine.is_editor_hint()

	if use_cache and _conditions != null:
		return _conditions

	var conditions := [] as Array[MoodCondition]

	for child in get_children():
		if child is MoodCondition:
			conditions.push_back(child)

	_conditions = conditions

	return conditions

func is_valid(cache: Dictionary = {}) -> bool:
	if and_all_conditions:
		return get_conditions().all(func (cond): cond.is_valid(cache))
	
	return get_conditions().any(func (cond): cond.is_valid(cache))

#endregion

#region Signal Hooks
