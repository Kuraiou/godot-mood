@tool
class_name MoodTransitionProperty extends MoodTransition

## The node whose properties we are going to evaluate against.
@export var condition_target: Node:
	set(val):
		if condition_target != val:
			# changing from one target to another instead of initial set
			if condition_target != null:
				condition_groups = [] as Array[MoodConditionGroup]
			condition_target = val
			notify_property_list_changed()

## The array of condition groups to evaluate. If any or all of them
## evaluate to true (based on [property and_all_groups]), then the transition is valid.
@export var condition_groups: Array[MoodConditionGroup] = []

## If true, all groups must evaluate to true for the transition to occur ("AND");
## if false, only one group must evaluate to true ("OR").
@export var and_all_groups: bool = true:
	set(val):
		if and_all_groups != val:
			and_all_groups = val
			notify_property_list_changed()

#region Private Helper Methods

func _is_valid() -> bool:
	if not condition_target:
		return false

	var cache := {}
	if and_all_groups:
		return condition_groups.all(func(cg): cg._is_valid(condition_target, cache))

	return condition_groups.any(func(cg): cg.is_valid(condition_target, cache))

#endregion
