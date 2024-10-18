@tool
extends VBoxContainer

@export var transition: MoodTransitionSignal:
	set(val):
		if transition == val:
			return

		if transition and transition.property_list_changed.is_connected(_refresh_selection):
			transition.property_list_changed.disconnect(_refresh_selection)

		transition = val

		if transition:
			transition.property_list_changed.connect(_refresh_selection)
			_refresh_selection()

@export var item_container: VBoxContainer
@export var signal_list_container: HBoxContainer

@export var signaler_button: Button
@export var signaler_label: Label

var _signal_selector

const SIGNAL_SELECTOR_SCENE: PackedScene = preload("res://addons/mood/scenes/editors/mood_ui_signal_selector.tscn")

func _on_popup_button_pressed() -> void:
	if _signal_selector:
		_signal_selector.queue_free()

	_signal_selector = SIGNAL_SELECTOR_SCENE.instantiate()
	_signal_selector.target_node = transition.signal_target
	_signal_selector.select_items_by_text(transition.signal_triggers)
	_signal_selector.on_signals_selected.connect(_update_signal_list)
	_signal_selector.popup_exclusive(EditorInterface.get_editor_main_screen())

func _update_signal_list(signals: Array[String]) -> void:
	transition.signal_triggers = signals
	transition.notify_property_list_changed()
	_signal_selector.queue_free()
	_signal_selector = null
	_refresh_selection()

func _refresh_selection() -> void:
	if is_instance_valid(transition.signal_target):
		signaler_label.text = transition.signal_target.name
		signaler_label.show()
		signaler_button.hide()
	else:
		signaler_label.hide()
		signaler_button.show()

	for child in item_container.get_children():
		child.free()

	if len(transition.signal_triggers) > 0:
		for sig in transition.signal_triggers:
			var lbl := Label.new()
			lbl.text = sig
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			item_container.add_child(lbl)
		signal_list_container.show()
	else:
		signal_list_container.hide()

func _on_select_signaler_button_pressed() -> void:
	EditorInterface.popup_node_selector(_on_select_signaler_confirmed)

func _on_select_signaler_confirmed(node_path: NodePath) -> void:
	transition.signal_target = get_tree().edited_scene_root.get_node(node_path)
