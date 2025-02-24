@tool
@icon("res://addons/mood/icons/eye-open.svg")
## A type of condition that evaluates whether a property or
## method result on an object meets a specific criteria.
class_name MoodConditionProperty extends MoodCondition

enum Operator { EQ = 0, LT = 1, LTE = 2, GT = 3, GTE = 4, NOT = 5 }

## The object who owns the property.
var _property_target: Node
@export var property_target: Node:
	get():
		if _property_target == null:
			if machine != null:
				_property_target = machine.target

		return _property_target
	set(value):
		if _property_target == value:
			return

		_property_target = value
		notify_property_list_changed()

## The property we're evaluating.
@export var property := ""
## The mechanism for comparison.
@export var comparator: Operator = Operator.EQ
## The value we're comparing against. Because it's variant,
## we have to do some shenanigans in the inspector plugin.
@export var criteria: Variant = null
@export var is_callable := false

#region Overrides

func _property_can_revert(property: StringName) -> bool:
	return property == &"property_target"

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"property_target":
			if machine:
				return machine.target
			return null
		_:
			return null

#endregion

#region Public Methods

## Return whether or not an input is valid.
##
## @param input [Node, Variant] The value to compare against. If
##   [evaluate_nodes] is true, then if the input is a Node and has
##   the [property] then the input will be overridden with that
##   property value.
## @param evaluate_nodes [bool]
## @return Whether or not the input is valid.
func is_valid(cache: Dictionary = {}) -> bool:
	if property not in cache:
		if is_callable:
			if not property_target.has_method(property):
				push_error("Expected Node %s to respond to %s but it does not" % [property_target.name, property])
				return false
			cache[property] = property_target.call(property)
		else:
			if property not in property_target:
				push_error("Expected Property %s to be in Node %s but it was not" % [property, property_target.name])
				return false
			cache[property] = property_target.get(property)

	var input: Variant = cache[property]

	match comparator:
		Operator.EQ:
			return input == criteria
		Operator.LT:
			return input < criteria
		Operator.LTE:
			return input <= criteria
		Operator.GT:
			return input > criteria
		Operator.GTE:
			return input >= criteria
		Operator.NOT:
			return input != criteria
	
	return false

#endregion

#region Signal Hooks
