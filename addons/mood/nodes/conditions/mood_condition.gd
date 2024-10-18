class_name MoodCondition extends MoodChild

## Return whether or not an input is valid.
##
## @param input [Node, Variant] The value to compare against. If
##   [evaluate_nodes] is true, then if the input is a Node and has
##   the [property] then the input will be overridden with that
##   property value.
## @param evaluate_nodes [bool]
## @return Whether or not the input is valid.
func _is_valid(target: Node, cache: Dictionary = {}) -> bool:
	return false
