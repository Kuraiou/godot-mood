extends Node

#region Constants

enum InputActionState {
	WAITING,
	JUST_PRESSED,
	ECHOED,
	JUST_RELEASED
}

#endregion

#region Public Variables
## put your @exports here.
##
## then put your var foo, var bar (variables you might touch from elsewhere) here.
#endregion

#region Private Variables
## put variables you won't touch here, prefixed by an underscore (`var _foo`).
#endregion

#region Signals

signal action_pressed(action: String, action_event: InputEvent)
signal action_echoed(action: String, action_event: InputEvent)
signal action_released(action: String, action_event: InputEvent)

#endregion

#region Overrides

var _action_tracking := {}

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_type():
		return

	var now := Time.get_unix_time_from_system()
	var use_exact: bool = bool(ProjectSettings.get_setting("mood/input/input_tracking_exact_match", false))

	for action: StringName in InputMap.get_actions():
		if action not in _action_tracking:
			_action_tracking[action] = {
				"state": InputActionState.WAITING,
				"strength": 0.0,
				"since": now
			}

		var delta_since_last_time = now - _action_tracking[action]["since"]

		if event.is_action_pressed(action, false, use_exact): # just pressed
			_action_tracking[action]["state"] = InputActionState.JUST_PRESSED
			_action_tracking[action]["since"] = now
			_action_tracking[action]["strength"] = event.get_action_strength(action, use_exact)
			action_pressed.emit(action, event)
		elif event.is_action_pressed(action, true, use_exact) and delta_since_last_time >= float(ProjectSettings.get_setting("mood/input/input_echo_delay_sec", 0.0)): # echo
			_action_tracking[action]["state"] = InputActionState.ECHOED
			_action_tracking[action]["since"] = now
			_action_tracking[action]["strength"] = event.get_action_strength(action, use_exact)

			action_echoed.emit(action, event)
		if event.is_action_released(action, use_exact):
			_action_tracking[action]["state"] = InputActionState.JUST_RELEASED
			_action_tracking[action]["time_between_actions"] = delta_since_last_time
			_action_tracking[action]["since"] = now
			_action_tracking[action]["strength"] = 0.0

			action_released.emit(action, event)
		elif _action_tracking[action]["state"] == InputActionState.JUST_RELEASED:
			_action_tracking[action]["state"] = InputActionState.WAITING
			_action_tracking[action]["time_between_actions"] = delta_since_last_time
			_action_tracking[action]["strength"] = 0.0
			_action_tracking[action]["since"] = now

#endregion

#region Public Methods
## put your methods here.
#endregion

#region Private Methods
## put methods you use only internally here, prefixed with an underscore.
#endregion

#region Signal Hooks
## put methods used as responses to signals here.
## we don't put #endregion here because this is the last block and when we use the
## UI to add signal hooks they always get concatenated at the end of the file.
