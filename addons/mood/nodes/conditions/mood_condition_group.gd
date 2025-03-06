@tool
@icon("res://addons/mood/icons/transmission-circle.svg")
class_name MoodConditionGroup extends MoodCondition

## A [MoodCondition] used to group multiple conditions together.[br]
## The [member Mood.root_condition] must be a [MoodCondition].[br]
## [MoodTransition] is a special type of [MoodConditionGroup] used when
## [member MoodMachine.evaluate_moods_directly] is [code]false[/code].

#region Public Variables

## If this is true, then the condition group evaluates to [code]true[/code] only if
## [b]all[/b] of the conditions evaluate to true (bitwise "AND"). Otherwise, the
## condition evaluates to true if [b]any[/b] of the conditions evaluate to true
## (bitwise "OR").
@export var and_all_conditions: bool = true

#endregion

#region Private Variables

## A cache of [MoodCondition] immediate children.
var _conditions: Array[MoodCondition]

#endregion

#region Overrides

func _get_configuration_warnings() -> PackedStringArray:
	var errors := []

	if get_conditions(false).size() == 0:
		errors.append("You must have at least one child MoodCondition.")

	return errors

#endregion

#region Public Methods

## Get a cached list of all immediate owned children of this node which
## are [MoodCondition]s or inherited [MoodCondition].
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

## This condition is valid if:[br]
## [br]
## 1. [member and_all_conditions] is [code]true[/code] and [b]all[/b] of its immediate [MoodCondition]
## children are true; or[br]
## 2. [member and_all_conditions] is [code]false[/code] and [b]any one[/b] of its immediate [MoodCondition]
## children are true.
func is_valid(cache: Dictionary = {}) -> bool:
	if and_all_conditions:
		return get_conditions().all(func (cond): cond.is_valid(cache))
	
	return get_conditions().any(func (cond): cond.is_valid(cache))

#endregion
