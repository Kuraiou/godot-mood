@tool
extends EditorPlugin

#region Constants

const GRAPH_SCENE: PackedScene = preload("res://addons/mood/ui_scenes/mood_machine_graph_ui.tscn")
const INSPECTOR_PLUGIN_SCRIPT = preload("res://addons/mood/sub_plugins/mood_inspector_plugin.gd")
const INSPECTOR_CONDITION_PLUGIN_SCRIPT = preload("res://addons/mood/sub_plugins/mood_condition_inspector_plugin.gd")
const CUSTOM_PROPERTIES: Dictionary = {
	"show_mood_graph": {"type": TYPE_BOOL, "default": true, "category": "graph"},
	"auto_switch_to_graph": {"type": TYPE_BOOL, "default": true, "category": "graph"},
	"use_low_processor_mode_for_graph": {"type": TYPE_BOOL, "default": true, "category": "graph", "advanced": true}
}

#endregion

#region Variables

var inspector_plugin_instance: EditorInspectorPlugin
var condition_inspector_instance: EditorInspectorPlugin
var graphs := {}
var previous_machine: MoodMachine = null
var current_machine: MoodMachine = null

#endregion

#region Setup/Teardown

func _enable_plugin() -> void:
	for config_name in CUSTOM_PROPERTIES:
		var prop_def := CUSTOM_PROPERTIES[config_name] as Dictionary
		var prop_name := "mood/%s/%s" % [prop_def.get("category", "config"), config_name]

		if ProjectSettings.has_setting(prop_name):
			continue

		var property = {
			"name": prop_name,
			"type": prop_def["type"]
		}
		for extra_key in ["hint", "hint_string"]:
			if prop_def.has(extra_key):
				property[extra_key] = prop_def[extra_key]

		ProjectSettings.set_setting(prop_name, prop_def["default"])
		ProjectSettings.add_property_info(property)
		ProjectSettings.set_initial_value(prop_name, prop_def["default"])
		ProjectSettings.set_as_basic(prop_name, !prop_def.has("advanced"))

func _disable_plugin() -> void:
	for config_name in CUSTOM_PROPERTIES:
		var def := CUSTOM_PROPERTIES.get(config_name) as Dictionary
		var prop_name := "mood/%s/%s" % [def.get("category", "config"), config_name]
		if ProjectSettings.has_setting(prop_name):
			ProjectSettings.clear(prop_name)

func _enter_tree() -> void:
	inspector_plugin_instance = INSPECTOR_PLUGIN_SCRIPT.new()
	add_inspector_plugin(inspector_plugin_instance)
	
	condition_inspector_instance = INSPECTOR_CONDITION_PLUGIN_SCRIPT.new()
	add_inspector_plugin(condition_inspector_instance)

func _exit_tree() -> void:
	remove_inspector_plugin(inspector_plugin_instance)
	remove_inspector_plugin(condition_inspector_instance)

	for machine in graphs:
		var config = graphs[machine]
		var scene = config["scene"]
		var button = config["button"]
		remove_control_from_bottom_panel(scene)
		scene.queue_free()
		if is_instance_valid(button): # may have already been freed
			button.queue_free()

	graphs = {}
	previous_machine = null
	current_machine = null

#endregion

#region Built-In Hooks

## Assign the current and previous machine and return if it is a machine, so we
## can properly behave in other hooks.
##
## _handles gets called before _make_visible, which gets called before _edit.
func _handles(object: Object) -> bool:
	if object is MoodMachine:
		_handle_machine(object as MoodMachine)
		return true
	elif object is MoodMachineChild:
		return _handle_machine((object as MoodMachineChild).machine)

	previous_machine = current_machine
	current_machine = null
	return false

func _handle_machine(machine: MoodMachine) -> bool:
	if machine == null: # child without attached machine passed through
		return false

	if not graphs.has(machine):
		_add_graph_for_machine(machine)

	previous_machine = current_machine
	current_machine = machine
	return true

## Make the button and graph visible, and if configured, switch to that.
## Because each machine we interact with will end up with its own editor instance,
## we need to know which function we're editing. because _make_visible happens
## after _handles, we can use the `current_machine` to do it.
func _make_visible(visible: bool) -> void:
	if visible:
		_current_button().show()
		if _get_plugin_setting("auto_switch_to_graph") == true:
			_current_button().toggled.emit(true)
	elif previous_machine:
		var config: Dictionary = graphs[previous_machine]

		# if we're still focused on the graph UI, we need to switch away since we're
		# about to make the button invisible.
		if config["scene"].visible:
			config["button"].toggled.emit(false)
			config["button"].get_parent().get_children()[0].toggled.emit(true)

		config["button"].hide()

## Handle the pre/post editing of the FSM. Because this is called after _handles,
## we want to operate on the previous_machine.
func _edit(object: Object) -> void:
	if object == null: # we focused off of our editing object so we want to use the previous_machine.
		#if previous_machine:
			#if previous_machine.has_unsaved_changes():
				#var dialog := ConfirmationDialog.new()
				#dialog.ok_button_text = "Save"
				#dialog.cancel_button_text = "Toss Changes"
				#dialog.title = "Unsaved Changes"
				#dialog.dialog_text = "You have unsaved changes to %s. Would you like to save them?" % previous_machine.name.replace("*", "")
				#dialog.confirmed.connect(_on_save_changes_dialog_confirmed.bind(previous_machine))
				#dialog.canceled.connect(_on_save_changes_dialog_canceled.bind(previous_machine))
				#dialog.popup_exclusive_centered(EditorInterface.get_editor_main_screen())
		return

#endregion

#region Signal Hooks

func _on_save_changes_dialog_confirmed(machine: MoodMachine) -> void:
	if not graphs.has(machine):
		_add_graph_for_machine(machine)

	machine.save_changes()

func _on_save_changes_dialog_canceled(machine: MoodMachine) -> void:
	if not graphs.has(machine):
		_add_graph_for_machine(machine)

	machine.reset_changes()

#endregion

#region Private Methods

func _get_plugin_setting(key: String) -> Variant:
	if key not in CUSTOM_PROPERTIES:
		return null

	var setting := "mood/%s/%s" % [CUSTOM_PROPERTIES[key].get("category", "config"), key]
	return ProjectSettings.get_setting(setting)

func _current_button() -> Button:
	if not current_machine:
		return null
	
	return graphs[current_machine]["button"] as Button

func _current_graph_scene() -> MoodMachineGraphUI:
	if not current_machine:
		return null

	return graphs[current_machine]["scene"] as MoodMachineGraphUI

func _add_graph_for_machine(machine: MoodMachine) -> void:
	if graphs.has(machine):
		return

	var graph_ctrl: MoodMachineGraphUI = GRAPH_SCENE.instantiate()
	graph_ctrl.target_machine = machine
	var button: Button = add_control_to_bottom_panel(graph_ctrl, "Mood FSM Editor")
	button.toggled.connect(_on_graph_toggled)

	graph_ctrl.hide()
	button.hide()

	graphs[machine] = {
		"scene": graph_ctrl,
		"button": button
	}

var default_low_processor_mode: bool
func _on_graph_toggled(toggled: bool) -> void:
	if _get_plugin_setting("use_low_processor_mode_for_graph"):
		if toggled:
			default_low_processor_mode = OS.low_processor_usage_mode
			OS.low_processor_usage_mode = true
		else:
			OS.low_processor_usage_mode = default_low_processor_mode

#endregion
