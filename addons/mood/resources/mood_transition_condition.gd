class_name MoodTransitionCondition extends Resource

enum Operator { EQ = 0, LT = 1, LTE = 2, GT = 3, GTE = 4, NOT = 5 }

## The property we're evaluating.
@export var property := ""
## The mechanism for comparison.
@export var comparator: Operator = Operator.EQ
## The value we're comparing against. Because it's variant,
## we have to do some shenanigans in the inspector plugin.
@export var value: Variant = null
@export var is_callable := false

## Return whether or not an input is valid.
##
## @param input [Node, Variant] The value to compare against. If
##   [evaluate_nodes] is true, then if the input is a Node and has
##   the [property] then the input will be overridden with that
##   property value.
## @param evaluate_nodes [bool]
## @return Whether or not the input is valid.
func _is_valid(target: Node, cache: Dictionary = {}) -> bool:
	if property not in cache:
		if is_callable:
			if not target.has_method(property):
				push_error("Expected Node %s to respond to %s but it does not" % [target.name, property])
				return false
			cache[property] = target.call(property)
		else:
			if property not in target:
				push_error("Expected Property %s to be in Node %s but it was not" % [property, target.name])
				return false
			cache[property] = target.get(property)

	var input: Variant = cache[property]

	match comparator:
		Operator.EQ:
			return input == value
		Operator.LT:
			return input < value
		Operator.LTE:
			return input <= value
		Operator.GT:
			return input > value
		Operator.GTE:
			return input >= value
		Operator.NOT:
			return input != value
	
	return false
