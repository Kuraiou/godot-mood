@tool
extends MoodTransition
class_name MoodTransitionProperty

## The node whose properties we are going to evaluate against.
@export var condition_target: Node:
	set(val):
		if condition_target != val:
			condition_target = val
			condition_groups = [] as Array[MoodTransitionConditionGroup]
			notify_property_list_changed()

## The array of condition groups to evaluate. If any or all of them
## evaluate to true (based on [property and_all_groups]), then the transition is valid.
@export var condition_groups: Array[MoodTransitionConditionGroup] = []

## If true, all groups must evaluate to true for the transition to occur ("AND");
## if false, only one group must evaluate to true ("OR").
@export var and_all_groups: bool = true:
	set(val):
		if and_all_groups != val:
			and_all_groups = val
			notify_property_list_changed()

#region Public Methods

func add_condition_group() -> MoodTransitionConditionGroup:
	var new_group = MoodTransitionConditionGroup.new()
	new_group.conditions = [MoodTransitionCondition.new()] as Array[MoodTransitionCondition]
	condition_groups.append(new_group)
	return new_group

#endregion

#region Private Helper Methods

func _is_valid() -> bool:
	if not condition_target:
		return false

	var cache := {}
	if and_all_groups:
		return condition_groups.all(func(cg): cg._is_valid(condition_target, cache))

	return condition_groups.any(func(cg): cg.is_valid(condition_target, cache))

#endregion
