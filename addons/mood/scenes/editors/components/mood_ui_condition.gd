@tool
extends VBoxContainer

#region Public Variables

@export var index_label: Label
@export var remove_button: Button
@export var condition_panel: PanelContainer

@export var _was_removed := false

@export var condition: MoodCondition:
	set(val):
		if val is not MoodCondition:
			return

		if condition == val:
			return

		if condition:
			condition.renamed.disconnect(_update_label)

		condition = val
		index_label.text = condition.name
		condition.renamed.connect(_update_label)
		
		if condition.has_method("get_sub_editor"):
			var editor: CanvasItem = condition.get_sub_editor()
			condition_panel.add_child(editor)

		#Returns this object's methods and their signatures as an Array of dictionaries. Each Dictionary contains the following entries:
#- name is the name of the method, as a String;
#- args is an Array of dictionaries representing the arguments;
#- default_args is the default arguments as an Array of variants;
#- flags is a combination of MethodFlags;
#- id is the method's internal identifier int;
#- return is the returned value, as a Dictionary;
#
#Note: The dictionaries of args and return are formatted identically to the results of get_property_list(), although not all entries are used.

#endregion

#region Private Variables

#endregion

#region Public Methods

#endregion

#region Signal Hooks

func _update_label():
	index_label.text = condition.name

func _on_remove_condition_pressed() -> void:
	_was_removed = true
	condition.queue_free.call_deferred()
	queue_free.call_deferred()
