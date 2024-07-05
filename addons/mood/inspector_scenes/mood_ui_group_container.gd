@tool
extends PanelContainer

const COND_GROUP_SCENE: PackedScene = preload("res://addons/mood/inspector_scenes/mood_ui_condition_group.tscn")

@export var transition: MoodTransitionProperty:
	set(val):
		if transition == val:
			return
		
		transition = val
		refresh_groups()
		
		notify_property_list_changed()
		update_configuration_warnings()

@onready var group_container: VBoxContainer = $Groups

func refresh_groups() -> void:
	if not is_node_ready():
		return

	for child in group_container.get_children():
		child.queue_free()

	var id := 0
	for condition_group: MoodTransitionConditionGroup in transition.condition_groups:
		add_condition_group(condition_group, id)

func add_condition_group(condition_group: MoodTransitionConditionGroup, id: int = 0) -> void:
		var scene := COND_GROUP_SCENE.instantiate() as MoodUiConditionGroup
		scene.condition_target = transition.condition_target
		scene.remove_group_button.pressed.connect(_on_remove_group_button_pressed.bind(scene))
		scene.index_label.text = "%s" % (id + 1)
		scene.group = condition_group
		group_container.add_child(scene)

func _on_remove_group_button_pressed(scene: MoodUiConditionGroup) -> void:
	pass
