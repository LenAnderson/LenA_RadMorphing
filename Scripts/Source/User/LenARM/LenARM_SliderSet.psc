Scriptname LenARM:LenARM_SliderSet extends Quest
{Contains SliderSet struct and relevant logic.}

Group LenARM
	LenARM_Debug Property D Auto Const
	LenARM_Util Property Util Auto Const
EndGroup

Group EnumUpdateType
	int Property EUpdateTypePeriodic = 0 Auto Const
	{update each time the morph timer is up}
	int Property EUpdateTypeOnSleep = 1 Auto Const
	{update after sleeping}
	int Property EUpdateTypeImmediate = 2 Auto Const
	{update immediately when the trigger value changes}
EndGroup

Group EnumApplyCompanion
	int Property EApplyCompanionNone = 0 Auto Const
	int Property EApplyCompanionFemale = 1 Auto Const
	int Property EApplyCompanionMale = 2 Auto Const
	int Property EApplyCompanionAll = 3 Auto Const
EndGroup

Group EnumOverrideBool
	int Property EOverrideBoolNoOverride = 0 Auto Const
	int Property EOverrideBoolTrue = 1 Auto Const
	int Property EOverrideBoolFalse = 2 Auto Const
EndGroup




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; Slider definition
Struct Slider
	string Name
	{name of the LooksMenu slider}
	float Value
	{value of the LooksMenu slider}
EndStruct




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; SliderSet definition

Struct SliderSet
	int Index
	{SliderSet number}

	bool IsUsed
	{TRUE if this SliderSet has been this up through MCM}


	;
	; MCM values
	;
	string SliderName
	{name of the sliders to morph, multiple sliders are separated by "|"}

	string TriggerName
	{name of the trigger value that is used to determine morphing}

	int UpdateType
	{when to update / apply morphs, see EnumUpdateType}
	
	float TargetMorph
	{how far to morph the sliders when the trigger value is maxed, 1.0 = 100%}
	float ThresholdMin
	{trigger value where morphing starts, between 0.0 and 1.0}
	float ThresholdMax
	{trigger value where morphing stops (i.e. fully morphed to TargetMorph), between 0.0 and 1.0}

	string UnequipSlot
	{IDs of the slots to unequip, multiple slots are separated by "|"}
	float ThresholdUnequip
	{% of TargetMorph when to unequip items, between 0.01 and 1.0, 1.0 = 100%}

	int ApplyCompanion
	{whether to apply morphs also to companions and which sex, see EnumApplyCompanion}

	bool OnlyDoctorCanReset
	{whether only doctors can reset morphs}
	bool IsAdditive
	{whether additional morphs are added on top after having a lower trigger value (if OnlyDoctorsCanReset)}
	bool HasAdditiveLimit
	{whether additive morphing is limited (if IsAdditive)}
	float AdditiveLimit
	{how far additional morphing goes on top of regular morphing, between 0.0 and 6.0, 1.0 = 100%}

	;
	; END: MCM values
	;


	int NumberOfSliderNames
	{how many slider names are used in this this}
	int NumberOfUnequipSlots
	{how many unequip slots are used in this this}

	float BaseMorph
	{base morph value for additive morphing; additive morphs are applied on top of this value}
	float CurrentMorph
	{current morph value}
	float FullMorph
	{full morph value, BaseMorph + CurrentMorph while respecting additive limits}

	float CurrentTriggerValue
	{latest trigger value that has been applied (i.e. morphed)}
	float NewTriggerValue
	{new trigger value that will be applied next time morphs are updated}
	bool HasNewTriggerValue
	{whether the new trigger value is still unapplied / unmorphed}
EndStruct




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; instances

; the slider sets
SliderSet[] SliderSets

; flattened array[idxSliderSet][idxSlider] (name and original morph)
Slider[] Sliders

; flattened array[idxSliderSet][idxSlotName]
string[] UnequipSlots

; flattened array[idxCompanion][idxSliderSet][idxSlider] (name and original morph)
Slider[] OriginalCompanionMorphs

; list of companions with saved original morphs
Actor[] Companions




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; getters

; For some reason doc comments from the first function after variable declarations are not picked up.
Function DummyFunction()
EndFunction

;
; Get the list of SliderSets.
;
SliderSet[] Function GetSliderSets()
	return SliderSets
EndFunction

;
; Get SliderSet number @idxSliderSet
;
SliderSet Function Get(int idxSliderSet)
	return SliderSets[idxSliderSet]
EndFunction

;
; Get the list of Sliders (name and original morph)
;
Slider[] Function GetSliders()
	return Sliders
EndFunction

;
; Get the list of base morphs (permanent morphs from additive SliderSets)
;
Slider[] Function GetBaseMorphs()
	D.Log("SliderSet.GetBaseMorphs")
	Slider[] baseMorphs = new Slider[0]
	int idxSliderSet = 0
	While (idxSliderSet < SliderSets.Length)
		Slider[] sliderSetBaseMorphs = SliderSet_GetBaseMorphs(idxSliderSet)
		int idxSlider = 0
		While (idxSlider < sliderSetBaseMorphs.Length)
			baseMorphs.Add(sliderSetBaseMorphs[idxSlider])
			idxSlider += 1
		EndWhile
		idxSliderSet += 1
	EndWhile
	return baseMorphs
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; instance methods

;
; Create and return a new SliderSet with the MCM values for SliderSet number @idxSliderSet
;
SliderSet Function SliderSet_Constructor(int idxSliderSet)
	D.Log("SliderSet.SliderSet_Constructor: " + idxSliderSet)
	SliderSet this = new SliderSet
	this.SliderName = MCM.GetModSettingString("LenA_RadMorphing", "sSliderName:Slider" + idxSliderSet)
	If (this.SliderName != "")
		this.Index = idxSliderSet
		this.IsUsed = true
		this.TriggerName = MCM.GetModSettingString("LenA_RadMorphing", "sTriggerName:Slider" + idxSliderSet)
		this.UpdateType = MCM.GetModSettingInt("LenA_RadMorphing", "iUpdateType:Slider" + idxSliderSet)
		this.TargetMorph = MCM.GetModSettingFloat("LenA_RadMorphing", "fTargetMorph:Slider" + idxSliderSet) / 100.0
		this.ThresholdMin = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdMin:Slider" + idxSliderSet) / 100.0
		this.ThresholdMax = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdMax:Slider" + idxSliderSet) / 100.0
		this.UnequipSlot = MCM.GetModSettingString("LenA_RadMorphing", "sUnequipSlot:Slider" + idxSliderSet)
		this.ThresholdUnequip = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdUnequip:Slider" + idxSliderSet) / 100.0
		this.ApplyCompanion = MCM.GetModSettingInt("LenA_RadMorphing", "iApplyCompanion:Slider" + idxSliderSet)
		this.OnlyDoctorCanReset = MCM.GetModSettingBool("LenA_RadMorphing", "bOnlyDoctorCanReset:Slider" + idxSliderSet)
		this.IsAdditive = MCM.GetModSettingBool("LenA_RadMorphing", "bIsAdditive:Slider" + idxSliderSet)
		this.HasAdditiveLimit = MCM.GetModSettingBool("LenA_RadMorphing", "bHasAdditiveLimit:Slider" + idxSliderSet)
		this.AdditiveLimit = MCM.GetModSettingFloat("LenA_RadMorphing", "fAdditiveLimit:Slider" + idxSliderSet) / 100.0

		string[] names = Util.StringSplit(this.SliderName, "|")
		this.NumberOfSliderNames = names.Length

		If (this.UnequipSlot != "")
			string[] slots = Util.StringSplit(this.UnequipSlot, "|")
			this.NumberOfUnequipSlots = slots.Length
		Else
			this.NumberOfUnequipSlots = 0
		EndIf
	Else
		this.IsUsed = false
	EndIf

	D.Log(this)
	return this
EndFunction


;
; Update the value of a morph trigger for SliderSet number @idxSliderSet
;
Function SliderSet_SetTriggerValue(int idxSliderSet, string triggerName, float value)
	SliderSet this = SliderSets[idxSliderSet]
	If (this.TriggerName == triggerName && this.NewTriggerValue != value && this.CurrentTriggerValue != value)
		D.Log("  SliderSet" + this.Index + ": CurrentTriggerValue=" + this.CurrentTriggerValue + "  NewTriggerValue=" + this.NewTriggerValue + " -> " + value)
		this.NewTriggerValue = value
		this.HasNewTriggerValue = true
	EndIf
EndFunction


;
; Get the list of morph updates (sliderName:newValue) for SliderSet number @idxSliderSet.
;
Slider[] Function SliderSet_CalculateMorphUpdates(int idxSliderSet)
	SliderSet this = SliderSets[idxSliderSet]
	Slider[] updates = new Slider[0]
	; check whether SliderSet is in use and whether a new / unapplied trigger value is available
	If (this.IsUsed && this.HasNewTriggerValue)
		D.Log("SliderSet.SliderSet_CalculateMorphUpdates: " + this.Index)
		; calculate new morph value based on trigger value and thresholds
		float newMorph
		If (this.NewTriggerValue < this.ThresholdMin)
			newMorph = 0.0
		ElseIf (this.NewTriggerValue > this.ThresholdMax)
			newMorph = 1.0
		Else
			newMorph = (this.NewTriggerValue - this.ThresholdMin) / (this.ThresholdMax - this.ThresholdMin)
		EndIf

		string baseMorphUpdate =    "  BaseMorph:      " + this.BaseMorph + " -> "
		string currentMorphUpdate = "  CurrentMorph:   " + this.CurrentMorph + " -> "
		string fullMorphUpdate =    "  FullMorph:      " + this.FullMorph + " -> "
		
		bool updateFullMorph = false
		If (this.OnlyDoctorCanReset)
			If (this.IsAdditive)
				; only doctors (base morphs), additive
				D.Log("  only doctors (base morphs), additive")
				If (newMorph > this.FullMorph)
					; new morph is higher than all applied morphs
					D.Log("  new morph is higher than all applied morphs")
					; increase current morph, don't change base morph, apply
					D.Log("  increase current morph, don't change base morph, apply")
					this.CurrentMorph = newMorph
					updateFullMorph = true
				ElseIf (newMorph > this.CurrentMorph)
					; new morph is lower than all applied morphs, but higher than the part linked to the previous trigger value
					D.Log("  new morph is lower than all applied morphs, but higher than the part linked to the previous trigger value")
					; increase current morph, don't change base morph, apply
					D.Log("  increase current morph, don't change base morph, apply")
					this.CurrentMorph = newMorph
					updateFullMorph = true
				Else
					; new morph is lower than all applied morphs and lower then the part linked to the previous trigger value
					D.Log("  new morph is lower than all applied morphs and lower then the part linked to the previous trigger value")
					; decrease current morph, increase base morph, don't apply
					D.Log("  decrease current morph, increase base morph, don't apply")
					this.BaseMorph += this.CurrentMorph - newMorph
					this.CurrentMorph = newMorph
				EndIf
			Else
				; only doctors, not additive
				D.Log("  only doctors, not additive")
				If (newMorph > this.FullMorph)
					; new morph is higher than all applied morphs
					D.Log("  new morph is higher than all applied morphs")
					; increase current morph, don't change base morph, apply
					D.Log("  increase current morph, don't change base morph, apply")
					this.CurrentMorph = newMorph
					updateFullMorph = true
				ElseIf (newMorph > this.CurrentMorph)
					; new morph is lower than all applied morphs, but higher than the part linked to the previous trigger value
					D.Log("  new morph is lower than all applied morphs, but higher than the part linked to the previous trigger value")
					; increase current morph, decrease base morph, don't apply
					D.Log("  increase current morph, decrease base morph, don't apply")
					this.BaseMorph -= Math.Min(this.BaseMorph, newMorph - this.CurrentMorph)
					this.CurrentMorph = newMorph
				Else
					; new morph is lower than all applied morphs and lower then the part linked to the previous trigger value
					D.Log("  new morph is lower than all applied morphs and lower then the part linked to the previous trigger value")
					; decrease current morph, increase base morph, don't apply
					D.Log("  decrease current morph, increase base morph, don't apply")
					this.BaseMorph += this.CurrentMorph - newMorph
					this.CurrentMorph = newMorph
				EndIf
			EndIf
		Else
			; no base morphs
			D.Log("  no base morphs")
			If (newMorph != this.CurrentMorph)
				; new morph is different than current morph
				D.Log("  new morph is different than current morph")
				; change current morph, apply
				D.Log("  change current morph, apply")
				this.CurrentMorph = newMorph
				updateFullMorph = true
			Else
				; new morph is same as current morph
				D.Log("  new morph is same as current morph")
				; don't change current morph, don't apply
				D.Log("  don't change current morph, don't apply")
			EndIf
		EndIf

		If (updateFullMorph)
			updates = SliderSet_CalculateFullMorphs(this.Index)
		EndIf

		baseMorphUpdate += this.BaseMorph
		currentMorphUpdate += this.CurrentMorph
		fullMorphUpdate += this.FullMorph
		D.Log("  TargetMorph:    " + this.TargetMorph)
		D.Log(baseMorphUpdate)
		D.Log(currentMorphUpdate)
		D.Log(fullMorphUpdate)

		this.CurrentTriggerValue = this.NewTriggerValue
		this.HasNewTriggerValue = false
	EndIf

	return updates
EndFunction

Function SliderSet_Print(int idxSliderSet)
	D.Log("SliderSet.SliderSet_Print: " + idxSliderSet)
	SliderSet this = SliderSets[idxSliderSet]
	D.Log("  Index: " + this.Index)
	D.Log("  IsUsed: " + this.IsUsed)
	D.Log("  SliderName: " + this.SliderName)
	D.Log("  TriggerName: " + this.TriggerName)
	D.Log("  UpdateType: " + this.UpdateType)
	D.Log("  TargetMorph: " + this.TargetMorph)
	D.Log("  ThresholdMin: " + this.ThresholdMin)
	D.Log("  ThresholdMax: " + this.ThresholdMax)
	D.Log("  UnequipSlot: " + this.UnequipSlot)
	D.Log("  ThresholdUnequip: " + this.ThresholdUnequip)
	D.Log("  ApplyCompanion: " + this.ApplyCompanion)
	D.Log("  OnlyDoctorCanReset: " + this.OnlyDoctorCanReset)
	D.Log("  IsAdditive: " + this.IsAdditive)
	D.Log("  HasAdditiveLimit: " + this.HasAdditiveLimit)
	D.Log("  AdditiveLimit: " + this.AdditiveLimit)
	D.Log("  NumberOfSliderNames: " + this.NumberOfSliderNames)
	D.Log("  NumberOfUnequipSlots: " + this.NumberOfUnequipSlots)
	D.Log("  BaseMorph: " + this.BaseMorph)
	D.Log("  CurrentMorph: " + this.CurrentMorph)
	D.Log("  FullMorph: " + this.FullMorph)
	D.Log("  CurrentTriggerValue: " + this.CurrentTriggerValue)
	D.Log("  NewTriggerValue: " + this.NewTriggerValue)
	D.Log("  HasNewTriggerValue: " + this.HasNewTriggerValue)
EndFunction


;
; Get the list of full morphs based on a CurrentMorph and BaseMorph
;
Slider[] Function SliderSet_CalculateFullMorphs(int idxSliderSet)
	D.Log("SliderSet.SliderSet_CalculateFullMorphs: " + idxSliderSet)
	SliderSet this = SliderSets[idxSliderSet]
	Slider[] updates = new Slider[0]
	float newMorph = this.CurrentMorph
	float fullMorph = newMorph

	If (this.OnlyDoctorCanReset)
		fullMorph += this.BaseMorph
		If (this.IsAdditive && this.HasAdditiveLimit)
			fullMorph = Math.Min(fullMorph, 1.0 + this.AdditiveLimit)
			D.Log("  additive limit: " + this.AdditiveLimit)
		EndIf
	EndIf

	If (this.FullMorph != fullMorph)
		this.FullMorph = fullMorph
		int sliderNameOffset = GetSliderNameOffset(this.Index)
		int idxSlider = 0
		float fullMorphValue = fullMorph * this.TargetMorph
		D.Log("  sliders:        " + this.SliderName)
		While (idxSlider < this.NumberOfSliderNames)
			Slider update = new Slider
			Slider slider = Sliders[sliderNameOffset + idxSlider]
			update.Name = slider.Name
			D.Log("    slider value: " + slider.Value)
			update.Value = slider.Value + fullMorphValue
			updates.Add(update)
			idxSlider += 1
		EndWhile
	EndIf
	return updates
EndFunction


;
; Get the percentage of morphs (base + current) currently applied for SliderSet number @idxSliderSet.
; Relative to lower and upper threshold.
; 
; When SliderSet.TargetMorph has been reached, morph percentage is 100% (=1.0).
; With additive morphing the value may go above 100%.
;
float Function SliderSet_GetMorphPercentage(int idxSliderSet)
	SliderSet this = SliderSets[idxSliderSet]
	return this.BaseMorph + this.CurrentMorph
EndFunction

;
; Get the percentage of base morphs (permanent morphs) currently applied for SliderSet number @idxSliderSet.
; Relative to lower and upper threshold.
;
float Function SliderSet_GetBaseMorphPercentage(int idxSliderSet)
	SliderSet this = SliderSets[idxSliderSet]
	return this.BaseMorph
EndFunction


;
; Get the list of base morphs (sliderName:currentBaseMorphValue) for SliderSet number @idxSliderSet.
;
Slider[] Function SliderSet_GetBaseMorphs(int idxSliderSet)
	SliderSet this = SliderSets[idxSliderSet]
	If (this.OnlyDoctorCanReset && this.IsAdditive && this.BaseMorph != 0.0)
		Slider[] baseMorphs = new Slider[0]
		int sliderNameOffset = GetSliderNameOffset(this.Index)
		int idxSlider = 0
		While (idxSlider < this.NumberOfSliderNames)
			Slider baseMorph = new Slider
			Slider slider = Sliders[sliderNameOffset + idxSlider]
			baseMorph.Name = slider.Name
			baseMorph.Value = slider.Value + this.BaseMorph * this.TargetMorph
			baseMorphs.Add(baseMorph)
			idxSlider += 1
		EndWhile
	EndIf
EndFunction


;
; Remove the BaseMorph for SliderSet number @idxSliderSet.
;
Function SliderSet_ClearBaseMorph(int idxSliderSet)
	SliderSet this = SliderSets[idxSliderSet]
	this.BaseMorph = 0
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; list functions


;
; Get the offset in the flattened SliderNames array for SliderSet number @idxSliderSet.
;
int Function GetSliderNameOffset(int idxSliderSet)
	int offset = 0
	int index = 0
	While (index < idxSliderSet)
		offset += SliderSets[index].NumberOfSliderNames
		index += 1
	EndWhile
	return offset
EndFunction


;
; Get the offset in the flattened UnequipSlots array for SliderSet number @idxSliderSet.
;
int Function GetUnequipSlotOffset(int idxSliderSet)
	int offset = 0
	int index = 0
	While (index < idxSliderSet)
		offset += SliderSets[index].NumberOfUnequipSlots
		index += 1
	EndWhile
	return offset
EndFunction


;
; Load all slider sets from MCM values and populate related arrays.
;
Function LoadSliderSets(int numberOfSliderSets, Actor player)
	D.Log("SliderSet.LoadSliderSets")
	
	; get overrides from MCM
	int overrideOnlyDoctorCanReset = MCM.GetModSettingInt("LenA_RadMorphing", "iOnlyDoctorCanReset:Override")
	int overrideIsAdditive = MCM.GetModSettingInt("LenA_RadMorphing", "iIsAdditive:Override")
	int overrideHasAdditiveLimit = MCM.GetModSettingInt("LenA_RadMorphing", "iHasAdditiveLimit:Override")
	float overrideAdditiveLimit = MCM.GetModSettingFloat("LenA_RadMorphing", "fAdditiveLimit:Override") / 100.0

	; create empty arrays
	If (!SliderSets)
		SliderSets = new SliderSet[0]
	EndIf
	If (!Sliders)
		Sliders = new Slider[0]
	EndIf
	If (!UnequipSlots)
		UnequipSlots = new string[0]
	EndIf
	If (!OriginalCompanionMorphs)
		OriginalCompanionMorphs = new Slider[0]
	EndIf

	; create SliderSets
	int idxSliderSet = 0
	While (idxSliderSet < numberOfSliderSets)
		SliderSet oldSet = None
		If (SliderSets.Length > idxSliderSet)
			SliderSets[idxSliderSet]
		EndIf
		SliderSet newSet = SliderSet_Constructor(idxSliderSet)
		If (SliderSets.Length < idxSliderSet + 1)
			SliderSets.Add(newSet)
		Else
			SliderSets[idxSliderSet] = newSet
		EndIf

		If (oldSet)
			; keep BaseMorph and CurrentMorph from existing SliderSet
			newSet.BaseMorph = oldSet.BaseMorph
			newset.CurrentMorph = oldSet.CurrentMorph
		EndIf

		; apply overrides
		If (overrideOnlyDoctorCanReset != EOverrideBoolNoOverride)
			newSet.OnlyDoctorCanReset = overrideOnlyDoctorCanReset == EOverrideBoolTrue
		EndIf
		If (overrideIsAdditive != EOverrideBoolNoOverride)
			newSet.IsAdditive = overrideIsAdditive == EOverrideBoolTrue
		EndIf
		If (overrideHasAdditiveLimit != EOverrideBoolNoOverride)
			newSet.HasAdditiveLimit = overrideHasAdditiveLimit == EOverrideBoolTrue
			newSet.AdditiveLimit = overrideAdditiveLimit
		EndIf

		; populate flattened arrays
		int sliderNameOffset = GetSliderNameOffset(idxSliderSet)
		If (newSet.IsUsed)
			string[] names = Util.StringSplit(newSet.SliderName, "|")
			int idxSlider = 0
			While (idxSlider < newset.NumberOfSliderNames)
				float morph = BodyGen.GetMorph(player, True, names[idxSlider], None)
				int currentIdx = sliderNameOffset + idxSlider
				If (!oldSet || idxSlider >= oldSet.NumberOfSliderNames)
					; insert into array
					Slider slider = new Slider
					slider.Name = names[idxSlider]
					slider.Value = morph
					Sliders.Insert(slider, currentIdx)
				Else
					; replace item
					Slider slider = Sliders[currentIdx]
					slider.Name = names[idxSlider]
					slider.Value = morph
				EndIf
				idxSlider += 1
			EndWhile
		EndIf

		; remove unused items
		If (oldSet && newSet.NumberOfSliderNames < oldSet.NumberOfSliderNames)
			Sliders.Remove(sliderNameOffset + newSet.NumberOfSliderNames, oldset.NumberOfSliderNames - newset.NumberOfSliderNames)
		EndIf

		int uneqipSlotOffset = GetUnequipSlotOffset(idxSliderSet)
		If (newSet.IsUsed && newset.NumberOfUnequipSlots > 0)
			string[] slots = Util.StringSplit(newSet.UnequipSlot, "|")
			int idxSlot = 0
			While (idxSlot < newset.NumberOfUnequipSlots)
				int currentIdx = uneqipSlotOffset + idxSlot
				If (!oldSet || idxSlot >= oldSet.NumberOfUnequipSlots)
					; insert into array
					UnequipSlots.Insert(slots[idxSlot] as int, currentIdx)
				Else
					; replace item
					UnequipSlots[currentIdx] = slots[idxSlot] as int
				EndIf
				idxSlot += 1
			EndWhile
		EndIf

		; remove unused items
		If (oldSet && newSet.NumberOfUnequipSlots < oldSet.NumberOfUnequipSlots)
			UnequipSlots.Remove(uneqipSlotOffset + newSet.NumberOfUnequipSlots, oldset.NumberOfUnequipSlots - newset.NumberOfUnequipSlots)
		EndIf

		idxSliderSet += 1
	EndWhile

	D.Log("  SliderSets:   " + SliderSets)
	D.Log("  Sliders:      " + Sliders)
	D.Log("  UnequipSlots: " + UnequipSlots)
EndFunction


;
; Update the value of a morph trigger.
;
Function SetTriggerValue(string triggerName, float value)
	D.Log("SliderSet.SetTriggerValue: " + triggerName + " = " + value)
	int idxSliderSet = 0
	While (idxSliderSet < SliderSets.Length)
		SliderSet_SetTriggerValue(idxSliderSet, triggerName, value)
		idxSliderSet += 1
	EndWhile
EndFunction


;
; Get the list of morph updates (sliderName:newValue) for all SliderSets with @updateType.
;
Slider[] Function CalculateMorphUpdates(int updateType)
	Slider[] updates = new Slider[0]
	int idxSliderSet = 0
	While (idxSliderSet < SliderSets.Length)
		SliderSet sliderSet = SliderSets[idxSliderSet]
		If (sliderSet.UpdateType == updateType)
			Slider[] sliderSetUpdates = SliderSet_CalculateMorphUpdates(idxSliderSet)
			int idxUpdate = 0
			While (idxUpdate < sliderSetUpdates.Length)
				Slider update = sliderSetUpdates[idxUpdate]
				updates.Add(update)
				idxUpdate += 1
			EndWhile
		EndIf
		idxSliderSet += 1
	EndWhile

	return updates
EndFunction


;
; Get the total (max) percentage of morphs (base + current) currently applied for all SliderSets.
; Relative to lower and upper threshold.
; 
; When SliderSet.TargetMorph has been reached, morph percentage is 100% (=1.0).
; With additive morphing the value may go above 100%.
;
float Function GetMorphPercentage()
	float morph = 0.0
	int idxSliderSet = 0
	While (idxSliderSet < SliderSets.Length)
		morph = Math.Max(morph, SliderSet_GetMorphPercentage(idxSliderSet))
		idxSliderSet += 1
	EndWhile
	return morph
EndFunction

;
; Get the amount of base morphs (permanent morphs) for all SliderSets.
;
float Function GetBaseMorphPercentage()
	float morph = 0.0
	int idxSliderSet = 0
	While (idxSliderSet < SliderSets.Length)
		morph = Math.Max(morph, SliderSet_GetBaseMorphPercentage(idxSliderSet))
		idxSliderSet += 1
	EndWhile
	return morph
EndFunction


Function ClearBaseMorphs()
	Slider[] updates = new Slider[0]
	int idxSliderSet = 0
	While (idxSliderSet < SliderSets.Length)
		SliderSet_ClearBaseMorph(idxSliderSet)
		idxSliderSet += 1
	EndWhile
EndFunction


Slider[] Function CalculateFullMorphs()
	Slider[] updates = new Slider[0]
	int idxSliderSet = 0
	While (idxSliderSet < SliderSets.Length)
		Slider[] sliderSetUpdates = SliderSet_CalculateFullMorphs(idxSliderSet)
		int idxUpdate = 0
		While (idxUpdate < sliderSetUpdates.Length)
			Slider update = sliderSetUpdates[idxUpdate]
			updates.Add(update)
			idxUpdate += 1
		EndWhile
		idxSliderSet += 1
	EndWhile

	return updates
EndFunction