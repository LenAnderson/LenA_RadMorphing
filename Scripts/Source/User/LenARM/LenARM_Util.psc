Scriptname LenARM:LenARM_Util extends Quest
{Utility functions.}

Group LenARM
	LenARM_Debug Property D Auto Const
EndGroup

;
; For some reason doc comments from the first function after variable declarations are not picked up.
;
Function DummyFunction()
EndFunction

;
; Split string @target into array at @delimiter
;
string[] Function StringSplit(string target, string delimiter)
	string[] result = new string[0]
	string current = target
	int idx = LL_Fourplay.StringFind(current, delimiter)
	While (idx > -1 && current)
		result.Add(LL_Fourplay.StringSubstring(current, 0, idx))
		current = LL_Fourplay.StringSubstring(current, idx+1)
		idx = LL_Fourplay.StringFind(current, delimiter)
	EndWhile
	If (current)
		result.Add(current)
	EndIf
	return result
EndFunction

;
; Check if @target begins with @toFind
;
bool Function StringStartsWith(string target, string toFind)
	return LL_Fourplay.StringFind(target, toFind) == 0
EndFunction


;
; Clamp @value between @limit1 and @limit2
;
float Function Clamp(float value, float limit1, float limit2)
	float lower = Math.Min(limit1, limit2)
	float upper = Math.Max(limit1, limit2)
	return Math.Min(Math.Max(value, lower), upper)
EndFunction