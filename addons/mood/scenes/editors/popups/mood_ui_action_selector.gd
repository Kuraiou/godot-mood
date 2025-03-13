@tool
extends ConfirmationDialog

@export var item_list: ItemList

signal on_actions_selected(actions: Array[String])

func select_items_by_text(texts: Array[String]) -> void:
	var idx := 0
	for action: StringName in InputMap.get_actions():
		if String(action) in texts:
			item_list.select(idx, false)
		idx += 1

func _on_confirmed() -> void:
	var indices = item_list.get_selected_items()
	var actions: Array[String] = []
	for id in indices:
		var txt = item_list.get_item_text(id)
		actions.append(txt)
	
	on_actions_selected.emit(actions)

func _ready() -> void:
	add_button("Unset", false, "unset")

func _refresh_items() -> void:
	item_list.clear()

	for action: StringName in InputMap.get_actions():
		item_list.add_item(String(action))

func _on_canceled() -> void:
	pass # Replace with function body.

func _on_custom_action(action: StringName) -> void:
	on_actions_selected.emit([] as Array[String])
	queue_free()
