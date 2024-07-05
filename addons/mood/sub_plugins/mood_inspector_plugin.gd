class_name MoodInspectorPlugin extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
	return object.has_method("has_unsaved_changes") and object.has_method("save_changes") and object.has_method("reset_changes")

func _parse_begin(object: Object) -> void:
	if object.has_unsaved_changes():
		if not object.name.ends_with("*"):
			object.name += "*"

		var btn = Button.new()
		btn.text = "Save Changes"
		btn.pressed.connect(_on_save_changes_pressed.bind(object))
		add_custom_control(btn)

		var btn2 = Button.new()
		btn2.text = "Discard Changes"
		btn2.pressed.connect(_on_discard_changes_pressed.bind(object))
		add_custom_control(btn2)
	elif object.name.ends_with("*"):
		object.name = object.name.rstrip("*")

func _on_save_changes_pressed(object: Object) -> void:
	object.save_changes()
	object.notify_property_list_changed()

func _on_discard_changes_pressed(object: Object) -> void:
	object.reset_changes()
	object.notify_property_list_changed()
