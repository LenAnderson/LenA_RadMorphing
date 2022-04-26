Scriptname LenARM:LenARM_Util extends Quest
{Utility functions.}

Group LenARM
	LenARM_Debug Property D AUto Const
EndGroup

;
; Split string @target into array at @delimiter
;
string[] Function StringSplit(string target, string delimiter)
	D.Log("splitting '" + target + "' with '" + delimiter + "'")
	string[] result = new string[0]
	string current = target
	int idx = LL_Fourplay.StringFind(current, delimiter)
	D.Log("split idx: " + idx + " current: '" + current + "'")
	While (idx > -1 && current)
		result.Add(LL_Fourplay.StringSubstring(current, 0, idx))
		current = LL_Fourplay.StringSubstring(current, idx+1)
		idx = LL_Fourplay.StringFind(current, delimiter)
		D.Log("split idx: " + idx + " current: '" + current + "'")
	EndWhile
	If (current)
		result.Add(current)
	EndIf
	D.Log("split result: " + result)
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