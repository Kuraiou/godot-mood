@tool
@icon("res://addons/mood/icons/circle-arrow.svg")

## A basic and straightforward mood component which allows you to just plainly
## delegate the behaviors back to the target. This is for when you prefer scripts
## with lots of code in them instead of well-isolated, reusable components.
class_name MoodMethodDelegator extends MoodScript

#region Public Variables

# For performance purposes we don't evaluate the validity of these calls, so don't
# do anything stupid, okay? :)

## If set, in  [method _process] call this method on the target, passing in delta.
@export var process_method: String:
	set(value):
		process_method = value
		update_configuration_warnings()
## If set, in  [method _physics_process] call this method on the target, passing in delta.
@export var physics_process_method: String:
	set(value):
		physics_process_method = value
		update_configuration_warnings()
## If set, in  [method _input] call this method on the target, passing in event.
@export var input_method: String:
	set(value):
		input_method = value
		update_configuration_warnings()
## If set, in  [method _unhandled_input] call this method on the target, passing in event.
@export var unhandled_input_method: String:
	set(value):
		unhandled_input_method = value
		update_configuration_warnings()

#endregion

#region Overrides

func _get_configuration_warnings() -> PackedStringArray:
	var errors: PackedStringArray = []

	for meth in [process_method, physics_process_method, input_method, unhandled_input_method]:
		if meth != "" and not target.has_method(meth):
			errors.push_back("%s does not respond to %s" % [target.name, meth])
	
	return errors

func _process(delta: float) -> void:
	if process_method:
		target.call(process_method, delta)

func _physics_process(delta: float) -> void:
	if physics_process_method:
		target.call(physics_process_method, delta)

func _input(event: InputEvent) -> void:
	if input_method:
		target.call(input_method, event)

func _unhandled_input(event: InputEvent) -> void:
	if unhandled_input_method:
		target.call(unhandled_input_method, event)

#endregion
