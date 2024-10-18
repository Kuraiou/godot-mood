@tool
class_name Recursion extends Object

static func __get_fn(t: Object, m: Variant) -> Callable:
	if m is Callable:
		return m
	if m is StringName and t.has_method(m):
		return Callable(t, m)

	return func(): pass
	
static func __execute_fn(fn: Callable, varargs: Array, deferred: bool) -> void:
	if fn == null:
		return

	if deferred:
		# @TODO: is the bindv reverse correct or what?
		fn.bindv(varargs).call_deferred()
	else:
		fn.callv(varargs)

## Run a method on a node and all its children recursively.
## @TODO: threading?
static func recurse(node: Node, method: Variant = null, varargs: Variant = [], deferred: bool = false, depth_first: bool = true) -> void:
	if varargs is not Array:
		varargs = [varargs]

	if deferred:
		varargs = varargs.reverse()

	# depth first = call on self, then call on children
	# breadth first = call on children, then call on self
	if depth_first:
		Recursion.__execute_fn(Recursion.__get_fn(node, method), varargs, deferred)

	for child in node.get_children():
		child.recurse(method, varargs, deferred)

	if not depth_first:
		Recursion.__execute_fn(Recursion.__get_fn(node, method), varargs, deferred)
