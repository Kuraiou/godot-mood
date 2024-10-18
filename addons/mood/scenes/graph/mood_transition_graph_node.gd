@tool
class_name MoodTransitionGraphNode
extends GraphNode

const CONDITION_SCENE := preload("res://addons/mood/scenes/editors/mood_ui_group_container.tscn")
const SIGNAL_SCENE := preload("res://addons/mood/scenes/editors/mood_ui_signal_transition.tscn")
const TIMER_SCENE := preload("res://addons/mood/scenes/editors/mood_ui_timer_transition.tscn")

@export var transition: MoodTransition:
	set(val):
		if transition != null or transition == val: # only allow write-once
			return

		transition = val

		name = transition.name
		title = transition.name
		position_offset = transition.get_meta("graph_position", Vector2.ZERO)

		var editor

		if transition is MoodTransitionProperty:
			editor = CONDITION_SCENE.instantiate()
			type_label.text = "Condition-Based"
			editor_panel.custom_minimum_size = Vector2(0, 300)
		elif transition is MoodTransitionTime:
			editor = TIMER_SCENE.instantiate()
			type_label.text = "Timer-Based"
			editor_panel.custom_minimum_size = Vector2(0, 125)
		elif transition is MoodTransitionSignal:
			editor = SIGNAL_SCENE.instantiate()
			type_label.text = "Signal-Based"
			editor_panel.custom_minimum_size = Vector2(0, 175)

		if editor:
			editor.transition = transition
			editor_panel.add_child(editor)

@export var editor_panel: ScrollContainer
@export var type_label: Label

func parent() -> MoodMachineChild:
	return transition

func _on_position_offset_changed() -> void:
	transition.set_meta("graph_position", position_offset)
