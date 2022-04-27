Scriptname LenARM:LenARM_Debug extends Quest
{Functions for logging and notifications.}

;
; For some reason doc comments from the first function after variable declarations are not picked up.
;
Function DummyFunction()
EndFunction

;
; Show message as notification on screen and write to papyrus log
;
; Prefixed with "[LenARM]".
Function Note(string msg)
	Debug.Notification("[LenARM] " + msg)
	Log(msg)
EndFunction

;
; Write message to papyrus log.
;
; Prefixed with "[LenARM]".
Function Log(string msg)
	Debug.Trace("[LenARM] " + msg)
EndFunction