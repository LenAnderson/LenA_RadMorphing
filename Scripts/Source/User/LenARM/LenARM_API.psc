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
; Get the overal progress of morphs.
;
float Function GetMorphPercentage()
	D.Log("API.GetMorphPercentage")
	return Main.GetMorphPercentage()
EndFunction


;
; Update the value of a morph trigger.
;
Function SetTriggerValue(string triggerName, float value)
	D.Log("API.SetTriggerValue: " + triggerName + " = " + value)
	Main.SetTriggerValue(triggerName, value)
EndFunction