@tool
class_name MoodGraphNode extends GraphNode

@export var mood: Mood:
	set(val):
		if mood != null or mood == val:
			return

		mood = val

		name = mood.name
		title = mood.get_meta("_graph_changed_name", name)
		position_offset = mood.get_meta("graph_position", Vector2.ZERO)

func parent() -> MoodMachineChild:
	return mood

func _on_position_offset_changed() -> void:
	mood.set_meta("graph_position", position_offset)
