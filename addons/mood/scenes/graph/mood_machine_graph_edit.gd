@tool
class_name MoodMachineGraphEdit extends GraphEdit

@onready var graph_popup: PopupMenu = $GraphPopupMenu
@onready var mood_popup: PopupMenu = $MoodPopupMenu
@onready var transition_popup: PopupMenu = $TransitionPopupMenu
@onready var change_name_dialog: ConfirmationDialog = $ChangeNameDialog
@onready var pick_transition_type_dialog: ConfirmationDialog = $PickTransitionTypeDialog

const MOOD_GRAPH_NODE_SCENE: PackedScene = preload("res://addons/mood/scenes/graph/mood_graph_node.tscn")
const TRANSITION_GRAPH_NODE_SCENE: PackedScene = preload("res://addons/mood/scenes/graph/mood_transition_graph_node.tscn")

const CONNECTION_TYPE_MOOD := 0
const CONNECTION_TYPE_TRANSITION := 1

var target_machine: MoodMachine = null:
	set(value):
		# disallow changing the target
		if target_machine != null and value != null:
			push_error("Tried to change Graph UI instance machine!")
			return

		if target_machine == value:
			return

		target_machine = value
		if not target_machine.mood_list_changed.is_connected(_on_machine_changed_mood):
			target_machine.mood_list_changed.connect(_on_machine_changed_mood)

		regenerate_nodes()

var popup_offset: Vector2
var hover_node: GraphNode
var name_change_node: GraphNode
var new_mood: Mood = null

#region Public Methods

func regenerate_nodes() -> void:
	# 1. reset the mood of the map including its children.
	clear_connections()
	for child in get_children():
		if child is GraphNode:
			child.queue_free()

	# 2. load moods from meta.
	load_existing_moods()
	
	# 3. load transitions from meta.
	load_existing_transitions()

func load_existing_moods() -> void:
	for mood: Mood in target_machine.find_children("*", "Mood", false) as Array[Mood]:
		_add_mood_to_graph(mood)

func load_existing_transitions() -> void:
	var selector := (target_machine.find_children("*", "MoodSelector", false) as Array[MoodSelector]).front()
	if selector:
		for trans: MoodTransition in selector.find_children("*", "MoodTransition") as Array[MoodTransition]:
			_add_transition_to_graph(trans)
	else:
		for trans: MoodTransition in target_machine.find_children("*", "MoodTransition") as Array[MoodTransition]:
			_add_transition_to_graph(trans)

# Remove a mood from the graph if possible..
func remove_mood(graph_node: MoodGraphNode) -> void:
	var mood := graph_node.mood
	graph_node.queue_free()
	mood.queue_free()

# Remove a mood from the graph if possible..
func remove_transition(graph_node: MoodTransitionGraphNode) -> void:
	var transition := graph_node.transition
	graph_node.queue_free()
	transition.queue_free()

#endregion

#region Signal Hooks

func _on_machine_changed_mood(_mood_node: Mood) -> void:
	print("regenerating nodes from mood change")
	regenerate_nodes()

var _pending_connection_request: Dictionary = {}
func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	print("attempting connection from %s:%s to %s:%s" % [from_node, from_port, to_node, to_port])
	
	_pending_connection_request = {
		"from_node": from_node,
		"from_port": from_port,
		"to_node": to_node,
		"to_port": to_port
	}
	match [from_port, to_port]:
		[CONNECTION_TYPE_MOOD, CONNECTION_TYPE_MOOD]:
			pick_transition_type_dialog.popup()
			%PickupTypeButton.grab_focus()

			# 1. modal dialog box to select transition type
			# 2. add transition of that type
			# 3. connect left node to left slot, right slot to right node
		[CONNECTION_TYPE_TRANSITION, CONNECTION_TYPE_TRANSITION]:
			pass # can't connect transitions
		_:
			connect_node(from_node, from_port, to_node, to_port)

func _get_selected_graph_nodes() -> Array[GraphNode]:
	var results: Array[GraphNode] = []

	for child in get_children():
		if child is GraphNode and (child as GraphNode).selected:
			results.append(child as GraphNode)

	return results
	
func _on_graph_node_mouse_entered(node: GraphNode):
	print("hovering over %s" % (node.name))
	hover_node = node

func _on_graph_node_mouse_exited(node: GraphNode):
	print("stopped hovering over %s" % (node.name))
	hover_node = null

func _on_popup_request(at_position: Vector2) -> void:
	print("in popup request")
	var selected_children: Array[GraphNode] = _get_selected_graph_nodes()

	if hover_node:
		hover_node.selected = true
		if hover_node not in selected_children:
			if len(selected_children) == 0:
				selected_children.append(hover_node)
			else:
				if Input.is_physical_key_pressed(_get_shortcut_key()):
					selected_children.append(hover_node)
				else:
					# if we're right-clicking on an unselected node and other nodes are
					# selected, we should deselect them and prefer only this node.
					for node: GraphNode in selected_children:
						node.selected = false

					selected_children = [hover_node]

	print("selected children", selected_children)

	popup_offset = at_position
	
	var target_popup: PopupMenu = graph_popup
	
	print("targeting popup")
	
	if hover_node and len(selected_children) > 0:
		if selected_children.all(func (n): return n is MoodGraphNode):
			target_popup = mood_popup
		elif selected_children.all(func (n): return n is MoodTransitionGraphNode):
			target_popup = transition_popup
		else:
			return # for now we can't handle both; @TODO add this functionality

		if len(selected_children) == 1:
			target_popup.set_item_text(0, target_popup.get_item_text(0).trim_suffix("s"))
			target_popup.set_item_disabled(1, false)
		else:
			target_popup.set_item_text(0, target_popup.get_item_text(0).trim_suffix("s") + "s")
			target_popup.set_item_disabled(1, true)

	# determine which popup depending on whether or not there's a graph node
	# at that position and/or whether or not there are already selected nodes.
	target_popup.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	target_popup.position = at_position + get_screen_position()
	print("showing popup now")
	target_popup.show()
	print("showed popup")

func _on_mood_popup_menu_id_pressed(id: int) -> void:
	print("mood popup menu id pressed ", id)
	match id:
		0: # delete selected moods
			for node: GraphNode in _get_selected_graph_nodes():
				if node is MoodGraphNode:
					remove_mood(node)
		1: # rename selected mood
			print("renaming mood")
			name_change_node = _get_selected_graph_nodes().filter(func (c): return c is MoodGraphNode).front()
			if name_change_node:
				print("assigning name change node")
				%OldNameLabel.text = name_change_node.title
				%NewNameEdit.text = name_change_node.title
				change_name_dialog.popup()
				%NewNameEdit.grab_focus()

func _on_transition_popup_menu_id_pressed(id: int) -> void:
	print("popup menu id pressed ", id)
	match id:
		0: # delete selected transitions
			for node: GraphNode in _get_selected_graph_nodes():
				if node is MoodTransitionGraphNode:
					remove_transition(node)
		1: # rename selected mood
			name_change_node = _get_selected_graph_nodes().filter(func (c): return c is MoodTransitionGraphNode).front()
			if name_change_node:
				%OldNameLabel.text = name_change_node.title
				%NewNameEdit.text = name_change_node.title
				change_name_dialog.popup()
				%NewNameEdit.grab_focus()

func _on_change_name_dialog_confirmed() -> void:
	print("change name dialog confirmed")
	var new_name: String = %NewNameEdit.text

	if new_name == "":
		print("* new name is no good")
		name_change_node = null
		return

	if new_mood:
		print("* creating new mood")
		new_mood.name = new_name
		target_machine.add_child(new_mood) # triggers mood_list_changed
		new_mood.owner = target_machine
		target_machine.notify_property_list_changed()
		print("* done")
	else:
		var parent = name_change_node.parent()
		name_change_node.title = new_name
		name_change_node.name = new_name
		parent.name = new_name

	new_mood = null
	name_change_node = null

func _on_new_name_edit_text_submitted(_new_text: String) -> void:
	print("new name edit text submitted")
	change_name_dialog.confirmed.emit()

func _on_change_name_dialog_canceled() -> void:
	print("change name dialog canceled")
	if new_mood: # cancel new node = remove that node
		new_mood.queue_free()
		name_change_node.queue_free()
		new_mood = null
		name_change_node = null

func _on_graph_popup_menu_id_pressed(id: int) -> void:
	print("graph popup menu id pressed ", id)
	match id:
		0: # Arrange Nodes
			arrange_nodes()
			for graph_node: GraphNode in find_children("*", "GraphNode") as Array[GraphNode]:
				graph_node.position_offset_changed.emit()
		1: # Create New mood
			var new_node_name = "New mood" % (len(find_children("New mood*")) + 1)
			var offset: Vector2 = popup_offset + scroll_offset
			new_mood = Mood.new()
			new_mood.name = new_node_name
			new_mood.set_meta("graph_position", offset)
			name_change_node = _add_mood_to_graph(new_mood, false)
			%OldNameLabel.text = "<New Mood>"
			%NewNameEdit.text = name_change_node.title
			change_name_dialog.popup()
			%NewNameEdit.grab_focus()

func _on_pick_transition_type_dialog_confirmed() -> void:
	print("transition type dialog confirmed")
	var from_node = _pending_connection_request["from_node"]
	var from_port = _pending_connection_request["from_port"]
	var to_node = _pending_connection_request["to_node"]
	var to_port = _pending_connection_request["to_port"]

	var lhs: GraphNode = find_child(from_node)
	var rhs: GraphNode = find_child(to_node)

	var type

	match %PickupTypeButton.selected:
		0: #"condition":
			type = MoodTransitionProperty
		1: #"signal":
			type = MoodTransitionSignal
		2: #"time":
			type = MoodTransitionTime

	var node := MoodTransitionGraphNode.new()
	var transition = type.new()
	transition.transition_from = lhs.mood
	transition.transition_to = rhs.mood
	transition.name =  "%sTo%s" % [lhs.name, rhs.name]	

	var selector := (target_machine.find_children("*", "MoodSelector", false) as Array[MoodSelector]).front()
	if selector:
		selector.add_child(transition)
		transition.owner = selector
		get_tree().edited_scene_root.notify_property_list_changed()
		EditorInterface.edit_node(transition)
	else:
		target_machine.add_child(transition)
		transition.owner = target_machine
		get_tree().edited_scene_root.notify_property_list_changed()

	print(get_tree().edited_scene_root.get_tree_string_pretty())

	EditorInterface.edit_node(transition)

	var transition_node := _add_transition_to_graph(transition)
	set_selected(transition_node)

#endregion

#region Private Methods

## Return META for Mac and CTRL for Windows.
func _get_shortcut_key() -> Key:
	if OS.get_name() == "macOS":
		return KEY_META
	else:
		return KEY_CTRL

## Given a [Mood], create a graph node for that mood and add it to
## the graph_node_to_mood_map.
func _add_mood_to_graph(mood: Mood, do_add_child: bool = true) -> GraphNode:
	var gn: GraphNode = MOOD_GRAPH_NODE_SCENE.instantiate() as MoodGraphNode

	gn.mood = mood
	gn.mouse_entered.connect(_on_graph_node_mouse_entered.bind(gn))
	gn.mouse_exited.connect(_on_graph_node_mouse_exited.bind(gn))

	if do_add_child:
		add_child(gn)
		gn.owner = self

	return gn

func _add_transition_to_graph(trans: MoodTransition) -> MoodTransitionGraphNode:
	var gn: GraphNode = TRANSITION_GRAPH_NODE_SCENE.instantiate()
	gn.transition = trans
	gn.mouse_entered.connect(_on_graph_node_mouse_entered.bind(gn))
	gn.mouse_exited.connect(_on_graph_node_mouse_exited.bind(gn))

	add_child(gn)
	gn.owner = self

	if trans.transition_from:
		var from_node := _get_graph_node_by_mood(trans.transition_from)
		if from_node:
			connect_node(from_node.name, 0, gn.name, 0)

	if trans.transition_to:
		var to_node := _get_graph_node_by_mood(trans.transition_to)
		if to_node:
			connect_node(gn.name, 0, to_node.name, 0)

	return gn
#
#func _update_meta(meta_name: String, value: Variant, object: Variant = target_machine) -> void:
	#var is_empty_val: bool = false
	#match typeof(value):
		#TYPE_ARRAY:
			#is_empty_val = value == []
		#TYPE_STRING, TYPE_STRING_NAME:
			#is_empty_val = value == ""
		#TYPE_DICTIONARY:
			#is_empty_val = value == {}
#
	#if is_empty_val:
		#object.remove_meta(meta_name)
	#else:
		#object.set_meta(meta_name, value)
		#
	## even if the object is not target machine, we want
	## to explicitly notify property update for the machine.
	#target_machine.notify_property_list_changed()
	#if object != target_machine:
		#object.notify_property_list_changed()

func _mood_to_definition(mood: Mood) -> Dictionary:
	return {"name": mood.name, "graph_position": mood.get_meta("graph_position", Vector2.ZERO)}

func _transition_to_definition(transition: MoodTransition) -> Dictionary:
	return {"name": transition.name, "graph_position": transition.get_meta("graph_position", Vector2.ZERO)}

func _get_graph_node_by_mood(mood: Mood) -> MoodGraphNode:
	for child: MoodGraphNode in find_children("*", "MoodGraphNode") as Array[MoodGraphNode]:
		if child.mood == mood:
			return child as MoodGraphNode

	return null

#endregion
