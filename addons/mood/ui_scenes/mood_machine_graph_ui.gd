@tool
class_name MoodMachineGraphUI extends GraphEdit

@onready var graph_popup: PopupMenu = $GraphPopupMenu
@onready var mood_popup: PopupMenu = $MoodPopupMenu
@onready var change_name_dialog: ConfirmationDialog = $ChangeNameDialog

const MOOD_GRAPH_NODE_SCENE: PackedScene = preload("res://addons/mood/ui_scenes/mood_ui_mood_graph_node.tscn")
const TRANSITION_GRAPH_NODE_SCENE: PackedScene = preload("res://addons/mood/ui_scenes/mood_ui_mood_transition_graph_node.tscn")

const CONNECTION_TYPE_MOOD := 0
const CONNECTION_TYPE_TRANSITION := 1

var target_machine: MoodMachine = null:
	set(value):
		# disallow changing the target
		if target_machine != null and value != null:
			push_error("Tried to change Graph UI instance machine!")
			return
		
		target_machine = value
		target_machine.mood_list_changed.connect(_on_machine_changed_mood)
		regenerate_nodes()

var new_moods: Array[Mood] = []
var deleted_moods: Array[Mood] = []
var changed_names := {}
var graph_node_to_mood_map = {}

var popup_offset: Vector2
var hover_node: GraphNode
var name_change_node: GraphNode

#region Public Methods

func regenerate_nodes() -> void:
	# 1. reset the mood of the map including its children.
	graph_node_to_mood_map = {}
	for child in get_children():
		if child is GraphNode:
			child.queue_free.call_deferred()

	# 2. load moods from meta.
	load_new_moods()
	load_existing_moods()
	
	# 3. load transitions from meta.
	load_new_transitions()
	load_existing_transitions()

	# 4. add new moods.
	for mood: Mood in new_moods:
		_add_mood_to_graph(mood)

func load_new_moods() -> void:
	new_moods = []

	var mood_meta: Array = target_machine.get_meta("_graph_new_moods", [])
	for mood_def: Dictionary in mood_meta:
		var mood := Mood.new()
		mood.name = mood_def["name"]
		mood.set_meta("graph_position", mood_def["graph_position"])
		new_moods.append(mood)

func load_existing_moods() -> void:
	deleted_moods = []
	changed_names = {}

	for mood: Mood in target_machine.find_children("*", "Mood") as Array[Mood]:
		if mood.get_meta("_graph_awaiting_deletion", false):
			deleted_moods.append(mood)
			continue

		var override_name: String = mood.get_meta("_graph_changed_name", "")
		if override_name != "":
			changed_names[mood] = override_name

		_add_mood_to_graph(mood)

func load_new_transitions() -> void:
	pass

func load_existing_transitions() -> void:
	for trans: MoodTransition in target_machine.find_children("*", "MoodTransition") as Array[MoodTransition]:
		trans.transition_from
		trans.transition_to

# Remove a mood from the graph if possible..
func remove_mood(graph_node: GraphNode) -> void:
	var mood: Mood = graph_node_to_mood_map[graph_node]

	if changed_names.has(mood):
		changed_names.erase(mood)

	if new_moods.has(mood):
		new_moods.erase(mood)
		_update_meta("_graph_new_moods", new_moods.map(_mood_to_definition))
	elif not deleted_moods.has(mood):
		deleted_moods.append(mood)
		_update_meta("_graph_awaiting_deletion", true, mood)

	graph_node_to_mood_map.erase(graph_node)
	remove_child(graph_node)
	graph_node.queue_free()

#endregion

#region Signal Hooks

func _on_machine_changed_mood(_mood_node: Mood) -> void:
	regenerate_nodes()

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	print("attempting connection from %s:%s to %s:%s" % [from_node, from_port, to_node, to_port])
	var lhs: GraphNode = find_child(from_node)
	var rhs:  GraphNode = find_child(to_node)

	match [from_port, to_port]:
		[CONNECTION_TYPE_MOOD, CONNECTION_TYPE_MOOD]:
			var node: GraphNode = GraphNode.new()
			# need to create a transition node and connect that.
		[CONNECTION_TYPE_TRANSITION, CONNECTION_TYPE_TRANSITION]:
			pass
		_:
			connect_node(from_node, from_port, to_node, to_port)
			# 
			

	connect_node(from_node, from_port, to_node, to_port)

	#match [lhs.get_output_port_type(from_port), rhs.get_input_port_type(to_port)]:
		#[CONNECTION_TYPE_MOOD, CONNECTION_TYPE_TRANSITION]: # accept the connection
			#connect_node(from_node, from_port, to_node, to_port)

func _update_mood_graph_position(graph_node: GraphNode, mood: Mood) -> void:
	mood.set_meta("graph_position", graph_node.position_offset)

func _get_selected_graph_nodes() -> Array[GraphNode]:
	var results: Array[GraphNode] = []

	for child in get_children():
		if child is GraphNode and (child as GraphNode).selected:
			results.append(child as GraphNode)

	return results
	
func _on_graph_node_mouse_entered(node: GraphNode):
	hover_node = node

func _on_graph_node_mouse_exited(node: GraphNode):
	hover_node = null

func _on_popup_request(at_position: Vector2) -> void:
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

	popup_offset = at_position
	
	var target_popup: PopupMenu = graph_popup
	
	if hover_node and len(selected_children) > 0:
		target_popup = mood_popup

		if len(selected_children) == 1:
			mood_popup.set_item_text(0, "Remove Mood")
			mood_popup.set_item_disabled(1, false)
		else:
			mood_popup.set_item_text(0, "Remove Moods")
			mood_popup.set_item_disabled(1, true)

	# determine which popup depending on whether or not there's a graph node
	# at that position and/or whether or not there are already selected nodes.
	target_popup.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	target_popup.position = at_position + get_screen_position()
	target_popup.show()

func _on_mood_popup_menu_id_pressed(id: int) -> void:
	match id:
		0: # delete selected moods
			for node: GraphNode in _get_selected_graph_nodes():
				remove_mood(node)
		1: # rename selected mood
			name_change_node = _get_selected_graph_nodes()[0]
			%OldNameLabel.text = name_change_node.title
			%NewNameEdit.text = name_change_node.title
			change_name_dialog.popup()
			%NewNameEdit.grab_focus()

func _on_change_name_dialog_confirmed() -> void:
	var new_name: String = %NewNameEdit.text

	if not name_change_node:
		return 

	if new_name == "":
		name_change_node = null
		return

	if name_change_node.title == new_name:
		name_change_node = null
		return

	var mood: Mood = graph_node_to_mood_map[name_change_node]
	if mood in new_moods:
		# if it's a new node we can just reflect the changes immediately.
		mood.name = new_name
		name_change_node.name = new_name
		name_change_node.title = new_name
		# we have to update meta b/c we convert to definition
		_update_meta("_graph_new_moods", new_moods.map(_mood_to_definition))
	else:
		# this is a name-change on an existing mood.
		changed_names[mood] = new_name
		_update_meta("_graph_changed_name", new_name, mood)

		mood.set_meta("_graph_changed_name", new_name)
		name_change_node.title = new_name + "*"

	name_change_node = null

func _on_new_name_edit_text_submitted(_new_text: String) -> void:
	change_name_dialog.confirmed.emit()

func _on_graph_popup_menu_id_pressed(id: int) -> void:
	match id:
		0: # Arrange Nodes
			arrange_nodes()
		1: # Create New mood
			var new_node_name = "New mood %s" % (len(new_moods) + 1)
			var offset: Vector2 = popup_offset + scroll_offset
			var mood: Mood = Mood.new()
			mood.owner = self
			mood.name = new_node_name
			mood.set_meta("graph_position", offset)

			new_moods.append(mood)
			_update_meta("_graph_new_moods", new_moods.map(_mood_to_definition))
			name_change_node = _add_mood_to_graph(mood)
			%OldNameLabel.text = "<New Node>"
			%NewNameEdit.text = name_change_node.title
			#%NewNameEdit.set_pr
			change_name_dialog.popup()
			%NewNameEdit.grab_focus()


		2: # save changes
			target_machine.save_changes()

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
func _add_mood_to_graph(mood: Mood) -> GraphNode:
	var gn: GraphNode = MOOD_GRAPH_NODE_SCENE.instantiate()
	graph_node_to_mood_map[gn] = mood

	gn.name = mood.name
	gn.title = changed_names.get(mood, mood.name)
	gn.position_offset = mood.get_meta("graph_position", Vector2.ZERO)

	gn.position_offset_changed.connect(_update_mood_graph_position.bind(gn, mood))
	gn.mouse_entered.connect(_on_graph_node_mouse_entered.bind(gn))
	gn.mouse_exited.connect(_on_graph_node_mouse_exited.bind(gn))

	graph_node_to_mood_map[gn] = mood
	add_child(gn)
	gn.owner = self
	return gn

func _add_transition_to_graph(trans: MoodTransition) -> GraphNode:
	var gn: GraphNode = TRANSITION_GRAPH_NODE_SCENE.instantiate()
	return gn

func _update_meta(meta_name: String, value: Variant, object: Variant = target_machine) -> void:
	var is_empty_val: bool = false
	match typeof(value):
		TYPE_ARRAY:
			is_empty_val = value == []
		TYPE_STRING, TYPE_STRING_NAME:
			is_empty_val = value == ""
		TYPE_DICTIONARY:
			is_empty_val = value == {}

	if is_empty_val:
		object.remove_meta(meta_name)
	else:
		object.set_meta(meta_name, value)
		
	# even if the object is not target machine, we want
	# to explicitly notify property update for the machine.
	target_machine.notify_property_list_changed()
	if object != target_machine:
		object.notify_property_list_changed()

	graph_popup.set_item_disabled(2, not target_machine.has_unsaved_changes())

func _mood_to_definition(mood: Mood) -> Dictionary:
	return {"name": mood.name, "graph_position": mood.get_meta("graph_position", Vector2.ZERO)}

#endregion
