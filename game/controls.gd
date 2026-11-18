extends RefCounted
const MAP = {
	"leftward":[[KEY_A,KEY_LEFT],[JOY_BUTTON_DPAD_LEFT]],
	"rightward":[[KEY_D,KEY_RIGHT],[JOY_BUTTON_DPAD_RIGHT]],
	"upward":[[KEY_W,KEY_UP],[JOY_BUTTON_DPAD_UP]],
	"downward":[[KEY_S,KEY_DOWN],[JOY_BUTTON_DPAD_DOWN]],
	"jab":[[KEY_J],[JOY_BUTTON_X]], "heavy":[[KEY_K],[JOY_BUTTON_Y]],
	"skill":[[KEY_L],[JOY_BUTTON_RIGHT_SHOULDER]], "dodge":[[KEY_SPACE,KEY_SHIFT],[JOY_BUTTON_B]],
	"use":[[KEY_E,KEY_ENTER],[JOY_BUTTON_A]], "back":[[KEY_ESCAPE],[JOY_BUTTON_START,JOY_BUTTON_BACK]],
	"advance":[[KEY_ENTER,KEY_E,KEY_J,KEY_SPACE],[JOY_BUTTON_A,JOY_BUTTON_X]]
}
static func install():
	for action in MAP:
		if InputMap.has_action(action): continue
		InputMap.add_action(action,0.25)
		for k in MAP[action][0]:
			var e=InputEventKey.new()
			e.physical_keycode=k
			InputMap.action_add_event(action,e)
		for b in MAP[action][1]:
			var e=InputEventJoypadButton.new()
			e.button_index=b
			InputMap.action_add_event(action,e)
	for spec in [["leftward",JOY_AXIS_LEFT_X,-1],["rightward",JOY_AXIS_LEFT_X,1],["upward",JOY_AXIS_LEFT_Y,-1],["downward",JOY_AXIS_LEFT_Y,1]]:
		var e=InputEventJoypadMotion.new()
		e.axis=spec[1]
		e.axis_value=spec[2]
		InputMap.action_add_event(spec[0],e)
