Scriptname LenARM:LenARM_Proxy_DeviousDevices extends Quest
{Proxy for Devious Devices.}

Group LenARM
	LenARM_Debug Property D Auto Const
	LenARM_Util Property Util Auto Const
EndGroup


;-----------------------------------------------------------------------------------------------------
; variables

; Devious Devices Library
DD:DD_Library DDL

; List of devices
Form[] Devices

Keyword DD_kw_RenderedItem

;
; For some reason doc comments from the first function after variable declarations are not picked up.
;
Function DummyFunction()
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; proxy functions

;
; Get DD Library
;
Function LoadDD()
	D.Log("DD.LoadDD")
	If (Game.IsPluginInstalled("Devious Devices.esm"))
		D.Log("  DD found")
		DDL = Game.GetFormFromFile(0x4C50, "Devious Devices.esm") as DD:DD_Library
		DD_kw_RenderedItem = DDL.GetPropertyValue("DD_kw_RenderedItem") as Keyword
	Else
		D.Log("  DD not found")
		DDL = None
	EndIf
EndFunction


;
; Check if the item is a devious device
;
bool Function CheckItem(Armor item)
	D.Log("DD.CheckItem: " + item)
	If (DDL == None)
		D.Log("DD not found or proxy not initialized")
		return false
	ElseIf (DD_kw_RenderedItem == None)
		D.Log("DD_kw_RenderedItem not found")
		return false
	Else
		D.Log("  Keywords:" + item.GetKeywords())
		return item.HasKeyword(DD_kw_RenderedItem)
	EndIf
EndFunction