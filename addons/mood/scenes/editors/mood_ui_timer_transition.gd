@tool
extends HBoxContainer

@export var transition: MoodTransitionTime:
	set(val):
		if transition == val:
			return

		if transition and transition.property_list_changed.is_connected(_refresh_selection):
			transition.property_list_changed.disconnect(_refresh_selection)

		transition = val

		if transition:
			transition.property_list_changed.connect(_refresh_selection)
			_refresh_selection()

@export var time_edit: LineEdit

func _on_time_edit_text_changed(new_text: String) -> void:
	var re = RegEx.new()
	re.compile(r'[^0-9.-]')
	new_text = re.sub(new_text, "", true)

	if new_text == "":
		new_text = "0" # float casting requirement

	time_edit.text = new_text

	transition.time = float(new_text)
	transition.notify_property_list_changed()

func _refresh_selection() -> void:
	time_edit.text = str(transition.time)
	time_edit.caret_column = len(time_edit.text)
