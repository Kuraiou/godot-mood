@tool
extends ConfirmationDialog

@export var item_list: ItemList
@export var action_search: LineEdit

signal on_actions_selected(actions: Array[StringName])

func select_items_by_text(texts: Array[StringName]) -> void:
	_refresh_items()

	var idx := 0
	for action: StringName in InputMap.get_actions():
		if String(action) in texts:
			item_list.select(idx, false)
		idx += 1

func _on_confirmed() -> void:
	var indices = item_list.get_selected_items()
	var actions := [] as Array[StringName]
	for id in indices:
		var txt = item_list.get_item_text(id)
		actions.append(StringName(txt))
	
	print("emitting ", actions)
	on_actions_selected.emit(actions)

func _ready() -> void:
	add_button("Unset", false, "unset")

func _refresh_items() -> void:
	item_list.clear()
	
	var filter: String = ""
	if is_instance_valid(action_search):
		filter = action_search.text

	for action: StringName in InputMap.get_actions():
		if len(filter) > 0 and not action.begins_with(filter):
			continue

		item_list.add_item(String(action))

func _on_canceled() -> void:
	pass # Replace with function body.

func _on_custom_action(action: StringName) -> void:
	on_actions_selected.emit([] as Array[StringName])
	queue_free()

func _on_action_search_text_changed(_new_text: String) -> void:
	print("search changed")
	_refresh_items()
