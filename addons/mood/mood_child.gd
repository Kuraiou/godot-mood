class_name MoodChild extends MoodMachineChild

## Any function which conditionally operates or responds to changes in mood
## should go under the Mood representing that mood; the [MoodChild] class
## acts as a simple wrapper around that behavior.
## Note that Moods can have a parent that is a Mood itself to perform
## combination behaviors.

## The [Mood] that acts as the fundamental parent mood.
## Because a [Mood] is itself a [MoodChild], it can have a parent mood that is
## different from itself; this allows for complex multi-mood assignment, or at
## least, ideally it will.
var mood: Mood = null:
	set(value):
		if mood == value:
			return
		
		mood = value

		# assign our processing status to match the mood's.
		set_process(mood.is_processing())
		set_physics_process(mood.is_physics_processing())
		set_process_input(mood.is_processing_input())
		set_process_unhandled_input(mood.is_processing_unhandled_input())

		# recursively applies mood assignment.
		for child: Node in get_children():
			if child is MoodChild:
				child.mood = value

		update_configuration_warnings()

#region Built-In Overrides

# @TODO: is this necessary?
func _init():
	super()

#endregion

#region Signal Hooks

## when a node comes in under us, if we can assign their mood, let's do so.
func _on_child_entered_tree(node: Node) -> void:
	super(node)

	if node is MoodChild:
		node.mood = self

#endregion

#region Public Methods

func recurse(method: StringName, varargs: Variant = [], deferred: bool = false) -> void:
	if varargs is not Array:
		varargs = [varargs]

	for child in get_children():
		if child is MoodChild:
			var fn = Callable(child, method)
			if deferred:
				# @TODO: is the bindv reverse correct or what?
				fn.bindv(varargs.reverse()).call_deferred()
			else:
				fn.callv(varargs)
			child.recurse(method, varargs, deferred)

#endregion
