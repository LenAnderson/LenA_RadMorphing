Scriptname LenARM:LenARM_API extends Quest
{API script for other mods to communicate with Rad Morphing Redux}


;-----------------------------------------------------------------------------------------------------
; this mod's resources
Group LenARM
	LenARM_Debug Property D Auto Const
	LenARM_Util Property Util Auto Const
	LenARM_Main Property Main Auto Const
EndGroup


;-----------------------------------------------------------------------------------------------------
; custom events

CustomEvent OnStartup
CustomEvent OnShutdown
CustomEvent OnMorphChange
CustomEvent OnTriggerAdd
CustomEvent OnTriggerRemove
CustomEvent OnTriggerUpdate




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; events


;-----------------------------------------------------------------------------------------------------
; game events

Event OnQuestInit()
	RegisterForCustomEvent(Main, "OnStartup")
	RegisterForCustomEvent(Main, "OnShutdown")
	RegisterForCustomEvent(Main, "OnMorphChange")
EndEvent

Event OnQuestShutdown()
	UnregisterForCustomEvent(Main, "OnStartup")
	UnregisterForCustomEvent(Main, "OnShutdown")
	UnregisterForCustomEvent(Main, "OnMorphChange")
EndEvent


;-----------------------------------------------------------------------------------------------------
; this mod's events

Event LenARM:LenARM_Main.OnStartup(LenARM:LenARM_Main sender, var[] args)
	SendCustomEvent("OnStartup")
EndEvent

Event LenARM:LenARM_Main.OnShutdown(LenARM:LenARM_Main sender, var[] args)
	SendCustomEvent("OnShutdown")
EndEvent

Event LenARM:LenARM_Main.OnMorphChange(LenARM:LenARM_Main sender, var[] args)
	D.Log("API.OnMorphChange: " + args)
	SendCustomEvent("OnMorphChange", args)
EndEvent




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; API functions

;
; For some reason doc comments from the first function after variable declarations are not picked up.
;
Function DummyFunction()
EndFunction


;
; Get the overall progress of morphs.
; Returns total morph percentage (0.0 - 1.0).
;
float Function GetMorphProgress()
	D.Log("API.GetMorphProgress")
	return Main.GetMorphPercentage()
EndFunction


;
; Register a trigger name with RMR.
; Returns false if the name is already registered, otherwise true.
;
bool Function RegisterTrigger(string triggerName)
	D.Log("API.RegisterTrigger: " + triggerName)
	bool isRegistered = Main.AddTriggerName(triggerName)
	If (isRegistered)
		var[] eventArgs = new var[1]
		eventArgs[0] = triggerName
		SendCustomEvent("OnTriggerAdd", eventArgs)
	EndIf
	return isRegistered
EndFunction

;
; Unregister a trigger name from RMR.
;
Function UnregisterTrigger(string triggerName)
	D.Log("API.UnregisterTrigger: " + triggerName)
	Main.RemoveTriggerName(triggerName)
	
	var[] eventArgs = new var[1]
	eventArgs[0] = triggerName
	SendCustomEvent("OnTriggerRemove", eventArgs)
EndFunction


;
; Update the value of a morph trigger.
;
Function UpdateTrigger(string triggerName, float value)
	D.Log("API.UpdateTrigger: " + triggerName + " = " + value)
	float actualValue = Main.SetTriggerValue(triggerName, value)
	
	var[] eventArgs = new var[2]
	eventArgs[0] = triggerName
	eventArgs[1] = actualValue
	SendCustomEvent("OnTriggerUpdate", eventArgs)
EndFunction


;
; Returns true if RMR is currently active / running.
;
bool Function IsRunning()
	return Main.GetIsRunning()
EndFunction