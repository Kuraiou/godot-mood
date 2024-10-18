@tool
extends EditorPlugin

#region Constants

const GRAPH_SCENE: PackedScene = preload("res://addons/mood/scenes/graph/mood_machine_graph_edit.tscn")

const INSPECTOR_CONDITION_PLUGIN_SCRIPT = preload("res://addons/mood/sub_plugins/mood_condition_inspector_plugin.gd")
const INSPECTOR_SIGNAL_PLUGIN_SCRIPT = preload("res://addons/mood/sub_plugins/mood_transition_signal_inspector_plugin.gd")

const CUSTOM_PROPERTIES: Dictionary = {
	"show_mood_graph": {"type": TYPE_BOOL, "default": true, "category": "graph"},
	"auto_switch_to_graph": {"type": TYPE_BOOL, "default": true, "category": "graph"},
	"use_low_processor_mode_for_graph": {"type": TYPE_BOOL, "default": true, "category": "graph", "advanced": true},
	"make_graph_properties_visible": {"type": TYPE_BOOL, "default": false, "category": "inspector", "advanced": true}
}

#endregion

#region Variables

var inspector_plugin_instance: EditorInspectorPlugin
var condition_inspector_instance: EditorInspectorPlugin
var signal_inspector_instance: EditorInspectorPlugin
var _graph: MoodMachineGraphEdit
var _button: Button

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
	condition_inspector_instance = INSPECTOR_CONDITION_PLUGIN_SCRIPT.new()
	add_inspector_plugin(condition_inspector_instance)
	
	signal_inspector_instance = INSPECTOR_SIGNAL_PLUGIN_SCRIPT.new()
	add_inspector_plugin(signal_inspector_instance)

func _exit_tree() -> void:
	remove_inspector_plugin(inspector_plugin_instance)
	remove_inspector_plugin(condition_inspector_instance)
	remove_inspector_plugin(signal_inspector_instance)

	if is_instance_valid(_graph):
		print("removing graph")
		remove_control_from_bottom_panel(_graph)
		print("removed graph, queueing free")
		_graph.queue_free()
		print("queued free")

	if is_instance_valid(_button):
		_button.queue_free()

#endregion

#region Built-In Hooks

## Assign the current and previous machine and return if it is a machine, so we
## can properly behave in other hooks.
##
## _handles gets called before _make_visible, which gets called before _edit.
func _handles(object: Object) -> bool:
	return object is MoodMachine or object is MoodMachineChild

func _edit(object: Object) -> void:
	if object is MoodMachine:
		if not _graph or _graph.target_machine != object:
			_clear_graph()
			_add_graph_for_machine(object as MoodMachine)
			_make_visible(true)
	elif object is MoodMachineChild:
		var machine: MoodMachine = (object as MoodMachineChild).machine
		if not _graph or _graph.target_machine != machine:
			_clear_graph()
			_add_graph_for_machine(machine)
			_make_visible(true)
	else:
		_clear_graph()

## Make the button and graph visible, and if configured, switch to that.
## Because each machine we interact with will end up with its own editor instance,
## we need to know which function we're editing. because _make_visible happens
## after _handles, we can use the `current_machine` to do it.
func _make_visible(visible: bool) -> void:
	if visible:
		if not _graph: # initial creation, we will make visible after creating graph
			return

		_button.show()
		if _get_plugin_setting("auto_switch_to_graph") == true:
			_button.toggled.emit(true)
	elif _graph and _button:
		_graph.hide()
		_button.get_parent().get_children()[0].toggled.emit(true)
		_button.toggled.emit(false)
		_button.hide()

#endregion

#region Private Methods

func _get_plugin_setting(key: String) -> Variant:
	if key not in CUSTOM_PROPERTIES:
		return null

	var setting := "mood/%s/%s" % [CUSTOM_PROPERTIES[key].get("category", "config"), key]
	return ProjectSettings.get_setting(setting)

func _clear_graph() -> void:
	if is_instance_valid(_graph):
		remove_control_from_bottom_panel(_graph)
		_graph.queue_free()
		_graph = null
	if is_instance_valid(_button):
		_button.queue_free()
		_button = null

func _add_graph_for_machine(machine: MoodMachine) -> void:
	_graph = GRAPH_SCENE.instantiate()
	_graph.target_machine = machine
	_button = add_control_to_bottom_panel(_graph, "Mood FSM Editor")
	_button.toggled.connect(_on_graph_toggled)

	_graph.hide()
	_button.hide()

var default_low_processor_mode: bool
func _on_graph_toggled(toggled: bool) -> void:
	if _get_plugin_setting("use_low_processor_mode_for_graph"):
		if toggled:
			default_low_processor_mode = OS.low_processor_usage_mode
			OS.low_processor_usage_mode = true
		else:
			OS.low_processor_usage_mode = default_low_processor_mode

#endregion
