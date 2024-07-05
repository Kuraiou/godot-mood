@tool
extends VBoxContainer

class_name MoodUiConditionGroup

const CONDITION_SCENE: PackedScene = preload("res://addons/mood/inspector_scenes/mood_ui_condition.tscn")

#region Public Variables

@export var index_label: Label
@export var remove_group_button: Button

@export var condition_target: Node:
	set(val):
		if val != condition_target:
			condition_target = val
			for cond in _condition_scenes:
				_condition_scenes[cond].condition_target = val

@export var group: MoodTransitionConditionGroup = null:
	set(val):
		if group == val:
			return
			
		for cond in _condition_scenes:
			_condition_scenes[cond].queue_free()

		_condition_scenes = {}

		group = val
		if is_node_ready():
			%AndAllConditions.button_pressed = group.and_all_conditions
			for child in %Conditions.get_children():
				child.queue_free()

		for cond: MoodTransitionCondition in group.conditions:
			add_condition(cond)

		notify_property_list_changed()

#endregion

#region Private Variables

var _condition_scenes := {}

#endregion

#region Built-In Hooks

func _ready() -> void:
	if group:
		%AndAllConditions.button_pressed = group.and_all_conditions

#endregion

#region Public Methods

func add_condition(condition: MoodTransitionCondition) -> Node:
	var current_condition_count := %Conditions.get_child_count()
	var cond_scene := CONDITION_SCENE.instantiate()

	cond_scene.condition_target = condition_target
	cond_scene.condition = condition
	cond_scene.index_label.text = "%s" % (current_condition_count + 1)
	cond_scene.remove_condition_button.pressed.connect(_on_remove_condition_pressed.bind(condition))

	if current_condition_count == 0: # this is our first/only condition so let's hide it.
		cond_scene.remove_condition_button.hide()

	_condition_scenes[condition] = cond_scene

	%Conditions.add_child(cond_scene)
	return cond_scene

#region Signal Hooks

func _on_add_condition_pressed() -> void:
	if %Conditions.get_child_count() == 1: # we're adding our second entry so show the remove button on the first
		%Conditions.get_child(0).remove_condition_button.show()

	var new_condition := MoodTransitionCondition.new()
	group.conditions.append(new_condition)
	group.notify_property_list_changed()
	add_condition(new_condition)

func _on_remove_condition_pressed(condition: MoodTransitionCondition):
	# @TODO: confirmation dialog (with config property?)
	group.conditions.erase(condition)
	group.notify_property_list_changed()

	_condition_scenes[condition].queue_free()
	_condition_scenes[condition].tree_exited.connect(_on_condition_erased)
	_condition_scenes.erase(condition)

func _on_all_of_toggled(toggled_on: bool) -> void:
	group.and_all_conditions = toggled_on

func _on_condition_erased():
	# we have to always have at least one condition in a group.
	match %Conditions.get_child_count():
		0:
			_on_add_condition_pressed()
			return # return so we don't double-notify below
		1:
			%Conditions.get_child(0).remove_condition_button.hide()

	var i := 1
	for cond in _condition_scenes:
		_condition_scenes[cond].index_label.text = "%s" % i
		i += 1

#endregion
