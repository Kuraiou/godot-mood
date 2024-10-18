@tool
class_name MoodUiCondition extends VBoxContainer

const VALID_TYPES := [
	TYPE_STRING, TYPE_STRING_NAME, TYPE_INT, TYPE_FLOAT, TYPE_BOOL
]

#region Public Variables

@export var index_label: Label
@export var remove_condition_button: Button

@export var _was_removed := false

@export var condition_target: Node:
	set(val):
		if condition_target == val:
			return

		%PropertySelectorButton.disabled = val == null
		condition_target = val
		_properties_by_name = {}
		for prop in val.get_property_list():
			_properties_by_name[prop["name"]] = prop

@export var condition: MoodCondition:
	set(val):
		if condition == val:
			return
		
		condition = val

		if is_node_ready():
			_update_property_editor()
		elif not ready.is_connected(_update_property_editor):
			ready.connect(_update_property_editor)

@onready var current_editor: Control = %PlaceholderEdit
@onready var editors: Array[Node] = %PropEditContainer.get_children()
@onready var enum_edit: OptionButton = %EnumEdit

#endregion

#region Private Variables

var _properties_by_name: Dictionary = {}

#endregion

#region Public Functions

#endregion

#region Signal Hooks

## strips out non-numeric values for the number editor.
func _on_number_edit_text_changed(new_text: String) -> void:
	var re = RegEx.new()
	re.compile(r'[^0-9.-]')
	new_text = re.sub(new_text, "", true)
	%NumberEdit.text = new_text
	%NumberEdit.caret_column = len(new_text)
	
	if condition:
		if new_text.contains("."):
			condition.value = float(new_text)
		else:
			condition.value = int(new_text)

## User selects a property...
func _on_property_selector_button_pressed() -> void:
	EditorInterface.popup_property_selector(condition_target, _on_prop_selected, VALID_TYPES)

func _on_condition_item_selected(index: int) -> void:
	if not condition:
		return
	
	condition.comparator = index

func _on_string_edit_text_changed(new_text: String) -> void:
	if condition:
		condition.value = new_text

func _on_enum_edit_item_selected(index: int) -> void:
	if condition:
		condition.value = enum_edit.get_item_text(index)

func _on_bool_edit_toggled(toggled_on: bool) -> void:
	if condition:
		condition.value = toggled_on

func _on_remove_condition_button_pressed() -> void:
	_was_removed = true
	queue_free.call_deferred()

#endregion

#region Private Helper Functions

## and we use the property to figure stuff out.
func _on_prop_selected(property_path: NodePath) -> void:
	var clean_name = property_path.get_subname(0)
	condition.property = clean_name # ":property" -> "property"
	_update_property_editor()

func _update_property_editor() -> void:
	if not condition:
		return

	if condition.property:
		%PropertySelectorButton.text = "Change Property"
		%SelectedProperty.text = condition.property
		%SelectedProperty.add_theme_color_override("font_color", Color("b9ec41"))
	else:
		%PropertySelectorButton.text = "Choose Property"
		%SelectedProperty.text = "Select A Property..."
		%SelectedProperty.add_theme_color_override("font_color", Color("7f7f7f"))

	%Condition.select(condition.comparator as int)

	if current_editor:
		current_editor.hide()

	var prop: Dictionary = _properties_by_name.get(condition.property, {})

	match prop.get("type", null):
		TYPE_BOOL:
			current_editor = %BoolEdit
			current_editor.button_pressed = !!condition.value
		TYPE_FLOAT, TYPE_INT:
			current_editor = %NumberEdit
			if condition.value:
				current_editor.text = "%s" % condition.value
			else:
				current_editor.text = "0"
		TYPE_STRING, TYPE_STRING_NAME:
			match prop["hint"]:
				PROPERTY_HINT_ENUM, PROPERTY_HINT_ENUM_SUGGESTION:
					enum_edit.clear()
					var idx := 0
					var selected := -1
					# @TODO handle special value assignments
					for enum_val in prop["hint_string"].split(","):
						enum_edit.add_item(enum_val, idx)
						if condition.value == enum_val:
							selected = idx
						idx += 1

					current_editor = enum_edit
					enum_edit.select(selected)
				_:
					current_editor = %StringEdit
					if condition.value:
						current_editor.text = condition.value
					else:
						current_editor.text = ""
		_:
			current_editor = %PlaceholderEdit

	if current_editor:
		current_editor.show()

#endregion
