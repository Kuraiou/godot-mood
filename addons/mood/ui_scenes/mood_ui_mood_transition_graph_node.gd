extends GraphNode

func _on_transition_type_selection_item_selected(index: int) -> void:
	match index:
		-1: # deselected
			$VBoxContainer/HSeparator.hide()
			$VBoxContainer/ConditionTypeContainer.hide()
			$VBoxContainer/TimeTypeAwaitTime.hide()
			# enable slot 1 to provide connection to input node whose property we care about.
		0: # condition
			$VBoxContainer/HSeparator.show()
			$VBoxContainer/ConditionTypeContainer.show()
			$VBoxContainer/TimeTypeAwaitTime.hide()
		1: # time
			$VBoxContainer/HSeparator.show()
			$VBoxContainer/ConditionTypeContainer.hide()
			$VBoxContainer/TimeTypeAwaitTime.show()
		2: # input
			$VBoxContainer/HSeparator.show()
			$VBoxContainer/ConditionTypeContainer.hide()
			$VBoxContainer/TimeTypeAwaitTime.hide()
