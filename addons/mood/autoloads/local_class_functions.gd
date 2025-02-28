class_name LocalClassFunctions extends Object

#region Constants

class LocalTreeItem:
	var parent: LocalTreeItem
	var children: Array[LocalTreeItem]
	var name: String
	var content: Variant

	func _init(_name: String, _content: Variant = null) -> void:
		self.name = _name
		self.content = _content
		
	func set_content(_content: Variant) -> void:
		self.content = _content

	func add_child(input: Variant) -> LocalTreeItem:
		if input is LocalTreeItem:
			children.append(input)
			input.parent = self
			return input
		elif input is Dictionary:
			var instance := LocalTreeItem.new(input["class"], input)
			instance.parent = self
			children.append(instance)
			return instance
		elif input is String or input is StringName:
			var instance := LocalTreeItem.new(input as String)
			instance.parent = self
			children.append(instance)
			return instance
		else:
			return null

	func print_tree(depth: int = 0) -> String:
		var str = ""
		if depth > 0:
			for i in range(depth):
				str += "  "
			str += "* "
		str += name
		str += "\n"
		for child in children:
			str += child.print_tree(depth + 1)

		return str

	# depth-first search
	func find_in_tree(child_name: String) -> LocalTreeItem:
		for child in children:
			if child.name == child_name:
				return child
			else:
				var found_child = child.find_in_tree(child_name)
				if found_child:
					return found_child
			
		return null

#endregion

#region Public Variables
## put your @exports here.
##
## then put your var foo, var bar (variables you might touch from elsewhere) here.
#endregion

#region Private Variables

static var _class_tree: LocalTreeItem
static var _icon_map: Dictionary[String, String]
## put variables you won't touch here, prefixed by an underscore (`var _foo`).
#endregion

#region Signals
## put your signal definitions here.
#endregion

#region Overrides
## virtual override methods here, e.g.
## _init, _ready
## _process, _physics_process
## _enter_tree, _exit_tree
#endregion

#region Public Methods

static func get_icon_path(klass: String) -> String:
	refresh_tree()
	
	return _icon_map[klass]

static func refresh_tree():
	var class_list := ProjectSettings.get_global_class_list()
	if _class_tree == null:
		_class_tree = LocalTreeItem.new("Object")

	for entry in ProjectSettings.get_global_class_list():
		if _class_tree.find_in_tree(entry["class"]): # already added!
			continue

		var parent := entry["base"] as String
		var parent_tree_node = _class_tree.find_in_tree(parent)

		if parent_tree_node == null: # parent does not yet exist
			var local_entry_idx = class_list.find_custom(func(e): return e["class"] == parent)
			var local_entry

			if local_entry_idx == -1: # must be built-in
				parent_tree_node = _class_tree.add_child(parent)
			else: # must be local
				local_entry = class_list[local_entry_idx]
				# we must reconstruct all parents
				var intermediaries_to_add = []
				var i = 0

				while local_entry_idx != -1 or i < 500:
					i += 1
					local_entry = class_list[local_entry_idx]
					intermediaries_to_add.push_front(local_entry)

					parent_tree_node = _class_tree.find_in_tree(local_entry["base"])
					if parent_tree_node != null: # found an anchor already existing
						break

					if local_entry in intermediaries_to_add:
						break

					var new_parent = local_entry["base"] as String

					local_entry_idx = class_list.find_custom(func(e): return e["class"] == new_parent)

				if i == 500:
					print("infinite loop")

				for intermediary in intermediaries_to_add:
					if parent_tree_node == null:
						parent_tree_node = _class_tree.add_child(intermediary["base"]) # global root
					if intermediary["icon"]:
						_icon_map[intermediary["class"]] = intermediary["icon"]
					parent_tree_node = parent_tree_node.add_child(intermediary)

		if entry["icon"]:
			_icon_map[entry["class"]] = entry["icon"]
		parent_tree_node.add_child(entry)
## put your methods here.
#endregion

#region Private Methods
## put methods you use only internally here, prefixed with an underscore.
#endregion

#region Signal Hooks
## put methods used as responses to signals here.
## we don't put #endregion here because this is the last block and when we use the
## UI to add signal hooks they always get concatenated at the end of the file.
