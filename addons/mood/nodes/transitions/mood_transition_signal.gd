@tool
class_name MoodTransitionSignal extends MoodTransition

@export var signal_target: Node:
	set(value):
		if signal_target == value:
			return
			
		signal_target = value
		notify_property_list_changed()

@export var signal_triggers: Array[String] = [] as Array[String]
@export var clear_on_transition := true
@export var clear_on_timer: Timer

var _received_signal := false

func _ready() -> void:
	for trigger in signal_triggers:
		if signal_target.has_signal(trigger):
			signal_target.connect(trigger, _receive_signal)

func _receive_signal() -> void:
	if _received_signal:
		return

	_received_signal = true

	if clear_on_timer:
		clear_on_timer.start()
		await clear_on_timer.timeout
		_received_signal = false

func _is_valid() -> bool:
	if _received_signal and clear_on_transition:
		_received_signal = false

	return _received_signal
