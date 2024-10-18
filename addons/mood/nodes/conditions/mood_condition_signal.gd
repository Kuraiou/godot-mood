class_name MoodConditionSignal extends MoodCondition

## A condition which connects to signals.

@export var signal_target: Node:
	get():
		if not signal_target:
			return target
		return signal_target
	set(value):
		if signal_target == value:
			return
		
		if signal_target:
			for trigger in signal_triggers:
				if signal_target.is_connected(trigger, _receive_signal):
					signal_target.disconnect(trigger, _receive_signal)

		signal_target = value

		signal_target.ready.connect(_refresh_signals)
		_refresh_signals()

## A list of signals by name to associate with the
## signal target.
@export var signal_triggers: Array[StringName] = [] as Array[StringName]:
	set(value):
		if signal_triggers == value:
			return

		# clear triggers so we don't have hanging triggers
		if signal_target:
			for trigger in signal_triggers:
				if signal_target.is_connected(trigger, _receive_signal):
					signal_target.disconnect(trigger, _receive_signal)

		signal_triggers = value
		_refresh_signals()

@export_group("Signal Flag Trigger Conditions", "trigger_")
## how many times one of the signals must be triggered before the flag is tripped.
@export var trigger_after_n_times := 1
## if set, when the flag would be set, delay the actual set until the
## timer ends.
@export var trigger_delay_timer: Timer

@export_group("Signal Flag Clearance", "clear_")
## If true, the received signal flag (when true) will be set to false
## once the transition occurs.
@export var clear_on_transition := true
## If set, the received signal flag (when true) will be set to false
## if the signal is received this many times.
@export var clear_after_count := 0
## If set, start the timer when signal is received and clear
## when the timer is done.
@export var clear_after_signal_received_timer: Timer
## If set, start the timer when signal is received and clear
## when the timer is done.
@export var clear_after_signal_flag_set_timer: Timer

var _received_signal := false
var _received_count := 0

#region Signal Hooks

func _receive_signal() -> void:
	_received_count += 1

	if clear_after_count > 0 and _received_count >= clear_after_count:
		_received_signal = false

	if _received_count >= trigger_after_n_times:
		if trigger_delay_timer:
			await _schedule_timer(trigger_delay_timer)
			
		_received_signal = true

		if clear_after_signal_flag_set_timer:
			await _schedule_timer(clear_after_signal_flag_set_timer)
			_received_signal = false

	if clear_after_signal_received_timer:
		await _schedule_timer(clear_after_signal_received_timer)
		_received_signal = false

#endregion

#region Private Functions

func _schedule_timer(timer: Timer) -> void:
	timer.start()
	await timer.timeout

## Whether or not the condition is valid. Used for transitioning state.
func _is_valid(target: Node, cache: Dictionary = {}) -> bool:
	if _received_signal and clear_on_transition:
		_received_signal = false

	return _received_signal

## ensure that all configured signals are wired up correctly.
func _refresh_signals() -> void:
	if not is_instance_valid(signal_target):
		return

	for trigger in signal_triggers:
		if not signal_target.is_connected(trigger, _receive_signal):
			signal_target.connect(trigger, _receive_signal)

#endregion
