@tool
extends EditorPlugin

#region Constants

const INSPECTOR_CONDITION_GROUP_SCRIPT = preload("res://addons/mood/sub_plugins/mood_condition_group_inspector_plugin.gd")

const CUSTOM_PROPERTIES: Dictionary = {
}

#endregion

#region Variables

var inspector_plugin_instance: EditorInspectorPlugin
var condition_inspector_instance: EditorInspectorPlugin

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
	condition_inspector_instance = INSPECTOR_CONDITION_GROUP_SCRIPT.new()
	add_inspector_plugin(condition_inspector_instance)
	

func _exit_tree() -> void:
	remove_inspector_plugin(condition_inspector_instance)

#endregion

#region Built-In Hooks

#endregion

#region Private Methods

func _get_plugin_setting(key: String) -> Variant:
	if key not in CUSTOM_PROPERTIES:
		return null

	var setting := "mood/%s/%s" % [CUSTOM_PROPERTIES[key].get("category", "config"), key]
	return ProjectSettings.get_setting(setting)

#endregion
