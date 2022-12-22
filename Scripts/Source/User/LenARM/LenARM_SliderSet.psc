Scriptname LenARM:LenARM_SliderSet extends Quest
{Contains SliderSet struct and relevant logic.}

Group LenARM
	LenARM_Debug Property D Auto Const
	LenARM_Util Property Util Auto Const
EndGroup

Group EnumUpdateType
	int Property EUpdateTypeImmediate = 0 Auto Const
	{update immediately when the trigger value changes}
	int Property EUpdateTypePeriodic = 1 Auto Const
	{update each time the morph timer is up}
	int Property EUpdateTypeOnSleep = 2 Auto Const
	{update after sleeping}
EndGroup

Group EnumApplyTo
	int Property EApplyToPlayer = 0 Auto Const
	int Property EApplyToCompanion = 1 Auto Const
	int Property EApplyToAll = 2 Auto Const
EndGroup

Group EnumApplySex
	int Property EApplySexAll = 0 Auto Const
	int Property EApplySexFemale = 1 Auto Const
	int Property EApplySexMale = 2 Auto Const
EndGroup

Group EnumUnequipAction
	int Property EUnequipActionUnequip = 0 Auto Const
	{unequip item and store in inventory}
	int Property EUnequipActionDrop = 1 Auto Const
	{unequip item and drop to ground}
	int Property EUnequipActionDestroy = 2 Auto Const
	{unequip item and destroy / remove}
EndGroup

Group EnumOverrideBool
	int Property EOverrideBoolNoOverride = 0 Auto Const
	int Property EOverrideBoolTrue = 1 Auto Const
	int Property EOverrideBoolFalse = 2 Auto Const
EndGroup

Group EnumOverrideUnequipAction
	int Property EOverrideUnequipActionNoOverride = 0 Auto Const
	{don't override the unequip action}
	int Property EOverrideUnequipActionUnequip = 1 Auto Const
	{unequip item and store in inventory}
	int Property EOverrideUnequipActionDrop = 2 Auto Const
	{unequip item and drop to ground}
	int Property EOverrideUnequipActionDestroy = 3 Auto Const
	{unequip item and destroy / remove}
EndGroup




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

	int ApplyTo
	{whether to apply this slider set to player, companions, or both; see EnumApplyTo}

	int Sex
	{whether to apply this slider set to all actors, only females, or only males, see EnumApplySex}

	string TriggerName
	{name of the trigger value that is used to determine morphing}

	bool InvertTriggerValue
	{whether to use inverted trigger value for morphing (1.0 - value)}

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
	int UnequipAction
	{whether to unequip and store in inventory, drop to ground, or destroy the unequipped items}
	float UnequipDropChance
	{chance to drop / destroy unequipped items if the respective unequip action is selected, between 0.0 and 1.0}

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
; Other struct definitions

Struct MorphUpdate
	int SliderSetIndex
	{index of the slider set that this update is coming from}
	string Name
	{name of the LooksMenu slider}
	float Value
	{value of the LooksMenu slider}
	bool ApplyPlayer
	{whether to apply to player}
	bool ApplyCompanion
	{whether to apply to companions}
	bool ApplyFemale
	{whether to apply to female actors}
	bool ApplyMale
	{whether to apply to male actors}
EndStruct

Struct CumulativeMorphUpdate
	string Name
	{name of the LooksMenu slider}
	float PlayerFemaleValue
	{value of the LooksMenu slider for female player}
	float PlayerMaleValue
	{value of the LooksMenu slider for male player}
	float CompanionFemaleValue
	{value of the LooksMenu slider for female companion}
	float CompanionMaleValue
	{value of the LooksMenu slider for male companion}
	bool ApplyPlayerFemale
	{whether to apply to female player}
	bool ApplyPlayerMale
	{whether to apply to male player}
	bool ApplyCompanionFemale
	{whether to apply to female companion}
	bool ApplyCompanionMale
	{whether to apply to male companion}
	bool ChangedPlayerFemale
	{whether changes have been made to female player}
	bool ChangedPlayerMale
	{whether changes have been made to male player}
	bool ChangedCompanionFemale
	{whether changes have been made to female companion}
	bool ChangedCompanionMale
	{whether changes have been made to male companion}
EndStruct

Struct UnequipSlot
	int Slot
	{slot number}
	bool ApplyPlayer
	{whether to unequip player}
	bool ApplyCompanion
	{whether to unequip companions}
	bool ApplyFemale
	{whether to unequip female companions}
	bool ApplyMale
	{whether to unequip male companions}
	bool Drop
	{whether to drop the unequipped item}
	bool Destroy
	{whether to destroy the unequipped item}
	float DropChance
	{chance to drop / unequip the item}
EndStruct




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; instances

; the slider sets
SliderSet[] SliderSetList

; flattened array[idxSliderSet][idxSlider]
string[] SliderNameList

; flattened array[idxSliderSet][idxSlot]
int[] UnequipSlotList

; list of used trigger names
string[] TriggerNameList




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; getters

; For some reason doc comments from the first function after variable declarations are not picked up.
Function DummyFunction()
EndFunction

;
; Get the list of SliderSetList.
;
SliderSet[] Function GetSliderSets()
	return SliderSetList
EndFunction

;
; Get SliderSet number @idxSliderSet
;
SliderSet Function Get(int idxSliderSet)
	return SliderSetList[idxSliderSet]
EndFunction

;
; Get the list of slider names
;
string[] Function GetSliderNames()
	return SliderNameList
EndFunction

;
; Get the list of base morphs (permanent morphs from additive SliderSetList)
;
CumulativeMorphUpdate[] Function GetBaseMorphs()
	D.Log("SliderSet.GetBaseMorphs")
	MorphUpdate[] baseMorphs = new MorphUpdate[0]
	int idxSliderSet = 0
	While (idxSliderSet < SliderSetList.Length)
		If (SliderSetList[idxSliderSet].IsUsed)
			MorphUpdate[] sliderSetBaseMorphs = SliderSet_GetBaseMorphs(idxSliderSet)
			int idxSlider = 0
			While (idxSlider < sliderSetBaseMorphs.Length)
				baseMorphs.Add(sliderSetBaseMorphs[idxSlider])
				idxSlider += 1
			EndWhile
		EndIf
		idxSliderSet += 1
	EndWhile
	return CalculateCumulativeMorphs(baseMorphs)
EndFunction

;
; Get the list of full morphs without recalculating
;
CumulativeMorphUpdate[] Function GetFullMorphs()
	D.Log("SliderSet.GetFullMorphs")
	MorphUpdate[] fullMorphs = new MorphUpdate[0]
	int idxSliderSet = 0
	While (idxSliderSet < SliderSetList.Length)
		If (SliderSetList[idxSliderSet].IsUsed)
			MorphUpdate[] sliderSetFullMorphs = SliderSet_GetFullMorphs(idxSliderSet)
			int idxSlider = 0
			While (idxSlider < sliderSetFullMorphs.Length)
				fullMorphs.Add(sliderSetFullMorphs[idxSlider])
				idxSlider += 1
			EndWhile
		EndIf
		idxSliderSet += 1
	EndWhile
	return CalculateCumulativeMorphs(fullMorphs)
EndFunction

;
; Get the list of used trigger names.
;
string[] Function GetTriggerNames()
	return TriggerNameList
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
	this.SliderName = MCM.GetModSettingString("RadMorphingRedux", "sSliderName:Slider" + idxSliderSet)
	If (this.SliderName != "")
		this.Index = idxSliderSet
		this.IsUsed = true
		this.ApplyTo = MCM.GetModSettingInt("RadMorphingRedux", "iApplyTo:Slider" + idxSliderSet)
		this.Sex = MCM.GetModSettingInt("RadMorphingRedux", "iSex:Slider" + idxSliderSet)
		this.TriggerName = MCM.GetModSettingString("RadMorphingRedux", "sTriggerName:Slider" + idxSliderSet)
		this.InvertTriggerValue = MCM.GetModSettingBool("RadMorphingRedux", "bInvertTriggerValue:Slider" + idxSliderSet)
		this.UpdateType = MCM.GetModSettingInt("RadMorphingRedux", "iUpdateType:Slider" + idxSliderSet)
		this.TargetMorph = MCM.GetModSettingFloat("RadMorphingRedux", "fTargetMorph:Slider" + idxSliderSet) / 100.0
		this.ThresholdMin = MCM.GetModSettingFloat("RadMorphingRedux", "fThresholdMin:Slider" + idxSliderSet) / 100.0
		this.ThresholdMax = MCM.GetModSettingFloat("RadMorphingRedux", "fThresholdMax:Slider" + idxSliderSet) / 100.0
		this.UnequipSlot = MCM.GetModSettingString("RadMorphingRedux", "sUnequipSlot:Slider" + idxSliderSet)
		this.ThresholdUnequip = MCM.GetModSettingFloat("RadMorphingRedux", "fThresholdUnequip:Slider" + idxSliderSet) / 100.0
		this.UnequipAction = MCM.GetModSettingInt("RadMorphingRedux", "iUnequipAction:Slider" + idxSliderSet)
		this.OnlyDoctorCanReset = MCM.GetModSettingBool("RadMorphingRedux", "bOnlyDoctorCanReset:Slider" + idxSliderSet)
		this.IsAdditive = MCM.GetModSettingBool("RadMorphingRedux", "bIsAdditive:Slider" + idxSliderSet)
		this.HasAdditiveLimit = MCM.GetModSettingBool("RadMorphingRedux", "bHasAdditiveLimit:Slider" + idxSliderSet)
		this.AdditiveLimit = MCM.GetModSettingFloat("RadMorphingRedux", "fAdditiveLimit:Slider" + idxSliderSet) / 100.0

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
	SliderSet this = SliderSetList[idxSliderSet]
	If (this.InvertTriggerValue)
		value = 1.0 - value
	EndIf
	If (this.TriggerName == triggerName && this.NewTriggerValue != value && this.CurrentTriggerValue != value)
		D.Log("  SliderSet" + this.Index + ": CurrentTriggerValue=" + this.CurrentTriggerValue + "  NewTriggerValue=" + this.NewTriggerValue + " -> " + value)
		this.NewTriggerValue = value
		this.HasNewTriggerValue = true
	EndIf
EndFunction


;
; Get the list of morph updates (sliderName:newValue) for SliderSet number @idxSliderSet.
;
MorphUpdate[] Function SliderSet_CalculateMorphUpdates(int idxSliderSet)
	SliderSet this = SliderSetList[idxSliderSet]
	MorphUpdate[] updates = new MorphUpdate[0]
	; check whether SliderSet is in use and whether a new / unapplied trigger value is available
	If (this.IsUsed && (this.HasNewTriggerValue || this.UpdateType == EUpdateTypeOnSleep))
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
		If (this.UpdateType == EUpdateTypeOnSleep)
			; sleep morphing -> only doctors (base morphs), additive, always add current value
			D.Log("  sleep morphing -> only doctors (base morphs), additive, always add current value")
			; don't change current morph, increase base morph, apply
			D.Log("  don't change current morph, increase base morph, apply")
			this.CurrentMorph = 0
			this.BaseMorph += newMorph
			updateFullMorph = true
		ElseIf (this.OnlyDoctorCanReset)
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
			If (newMorph != this.FullMorph)
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

		updates = SliderSet_CalculateFullMorphs(this.Index, updateFullMorph)

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


;
; Get the list of full morphs based on a CurrentMorph and BaseMorph
;
MorphUpdate[] Function SliderSet_CalculateFullMorphs(int idxSliderSet, bool calculateUpdates=true)
	D.Log("SliderSet.SliderSet_CalculateFullMorphs: " + idxSliderSet)
	SliderSet this = SliderSetList[idxSliderSet]
	MorphUpdate[] updates = new MorphUpdate[0]
	float newMorph = this.CurrentMorph
	float fullMorph = newMorph

	If (this.OnlyDoctorCanReset || this.UpdateType == EUpdateTypeOnSleep)
		fullMorph += this.BaseMorph
		If ((this.IsAdditive || this.UpdateType == EUpdateTypeOnSleep) && this.HasAdditiveLimit)
			fullMorph = Math.Min(fullMorph, 1.0 + this.AdditiveLimit)
			D.Log("  additive limit: " + this.AdditiveLimit)
		EndIf
	EndIf

	If (this.FullMorph != fullMorph)
		this.FullMorph = fullMorph
		If (calculateUpdates)
			int sliderNameOffset = GetSliderNameOffset(this.Index)
			int idxSlider = 0
			float fullMorphValue = fullMorph * this.TargetMorph
			D.Log("  sliders:        " + this.SliderName)
			While (idxSlider < this.NumberOfSliderNames)
				MorphUpdate update = new MorphUpdate
				update.SliderSetIndex = idxSliderSet
				update.Name = SliderNameList[sliderNameOffset + idxSlider]
				update.Value = fullMorphValue
				update.ApplyPlayer = this.ApplyTo == EApplyToAll || this.ApplyTo == EApplyToPlayer
				update.ApplyCompanion = this.ApplyTo == EApplyToAll || this.ApplyTo == EApplyToCompanion
				update.ApplyFemale = this.Sex == EApplySexAll || this.Sex == EApplySexFemale
				update.ApplyMale = this.Sex == EApplySexAll || this.Sex == EApplySexMale
				updates.Add(update)
				idxSlider += 1
			EndWhile
		EndIf
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
	SliderSet this = SliderSetList[idxSliderSet]
	return this.BaseMorph + this.CurrentMorph
EndFunction

;
; Get the percentage of base morphs (permanent morphs) currently applied for SliderSet number @idxSliderSet.
; Relative to lower and upper threshold.
;
float Function SliderSet_GetBaseMorphPercentage(int idxSliderSet)
	SliderSet this = SliderSetList[idxSliderSet]
	return this.BaseMorph
EndFunction


;
; Get the list of base morphs (sliderName:currentBaseMorphValue) for SliderSet number @idxSliderSet.
;
MorphUpdate[] Function SliderSet_GetBaseMorphs(int idxSliderSet)
	SliderSet this = SliderSetList[idxSliderSet]
	MorphUpdate[] baseMorphs = new MorphUpdate[0]
	If (this.OnlyDoctorCanReset && this.IsAdditive && this.BaseMorph != 0.0)
		int sliderNameOffset = GetSliderNameOffset(this.Index)
		int idxSlider = 0
		While (idxSlider < this.NumberOfSliderNames)
			MorphUpdate baseMorph = new MorphUpdate
			baseMorph.SliderSetIndex = idxSliderSet
			baseMorph.Name = SliderNameList[sliderNameOffset + idxSlider]
			baseMorph.Value = this.BaseMorph * this.TargetMorph
			baseMorph.ApplyPlayer = this.ApplyTo == EApplyToAll || this.ApplyTo == EApplyToPlayer
			baseMorph.ApplyCompanion = this.ApplyTo == EApplyToAll || this.ApplyTo == EApplyToCompanion
			baseMorph.ApplyFemale = this.Sex == EApplySexAll || this.Sex == EApplySexFemale
			baseMorph.ApplyMale = this.Sex == EApplySexAll || this.Sex == EApplySexMale
			baseMorphs.Add(baseMorph)
			idxSlider += 1
		EndWhile
	EndIf
	return baseMorphs
EndFunction


;
; Get the list of full morphs for SliderSet number @idxSliderSet without recalculating.
;
MorphUpdate[] Function SliderSet_GetFullMorphs(int idxSliderSet)
	SliderSet this = SliderSetList[idxSliderSet]
	MorphUpdate[] fullMorphs = new MorphUpdate[0]
	int sliderNameOffset = GetSliderNameOffset(this.Index)
	int idxSlider = 0
	While (idxSlider < this.NumberOfSliderNames)
		MorphUpdate fullMorph = new MorphUpdate
		fullMorph.SliderSetIndex = idxSliderSet
		fullMorph.Name = SliderNameList[sliderNameOffset + idxSlider]
		fullMorph.Value = this.FullMorph * this.TargetMorph
		fullMorph.ApplyPlayer = this.ApplyTo == EApplyToAll || this.ApplyTo == EApplyToPlayer
		fullMorph.ApplyCompanion = this.ApplyTo == EApplyToAll || this.ApplyTo == EApplyToCompanion
		fullMorph.ApplyFemale = this.Sex == EApplySexAll || this.Sex == EApplySexFemale
		fullMorph.ApplyMale = this.Sex == EApplySexAll || this.Sex == EApplySexMale
		fullMorphs.Add(fullMorph)
		idxSlider += 1
	EndWhile
	return fullMorphs
EndFunction


;
; Remove the BaseMorph for SliderSet number @idxSliderSet.
;
Function SliderSet_ClearBaseMorph(int idxSliderSet)
	SliderSet this = SliderSetList[idxSliderSet]
	this.BaseMorph = 0
EndFunction


;
; Print details of SliderSet number @idxSliderSet.
;
Function SliderSet_Print(int idxSliderSet)
	D.Log("SliderSet.SliderSet_Print: " + idxSliderSet)
	SliderSet this = SliderSetList[idxSliderSet]
	D.Log("  Index:                " + this.Index)
	D.Log("  IsUsed:               " + this.IsUsed)
	D.Log("  SliderName:           " + this.SliderName)
	D.Log("  ApplyTo:              " + this.ApplyTo)
	D.Log("  Sex:                  " + this.Sex)
	D.Log("  TriggerName:          " + this.TriggerName)
	D.Log("  InvertTriggerValue:   " + this.InvertTriggerValue)
	D.Log("  UpdateType:           " + this.UpdateType)
	D.Log("  TargetMorph:          " + this.TargetMorph)
	D.Log("  ThresholdMin:         " + this.ThresholdMin)
	D.Log("  ThresholdMax:         " + this.ThresholdMax)
	D.Log("  UnequipSlot:          " + this.UnequipSlot)
	D.Log("  UnequipAction:        " + this.UnequipAction)
	D.Log("  UnequipDropChance:    " + this.UnequipDropChance)
	D.Log("  ThresholdUnequip:     " + this.ThresholdUnequip)
	D.Log("  OnlyDoctorCanReset:   " + this.OnlyDoctorCanReset)
	D.Log("  IsAdditive:           " + this.IsAdditive)
	D.Log("  HasAdditiveLimit:     " + this.HasAdditiveLimit)
	D.Log("  AdditiveLimit:        " + this.AdditiveLimit)
	D.Log("  NumberOfSliderNames:  " + this.NumberOfSliderNames)
	D.Log("  NumberOfUnequipSlots: " + this.NumberOfUnequipSlots)
	D.Log("  BaseMorph:            " + this.BaseMorph)
	D.Log("  CurrentMorph:         " + this.CurrentMorph)
	D.Log("  FullMorph:            " + this.FullMorph)
	D.Log("  CurrentTriggerValue:  " + this.CurrentTriggerValue)
	D.Log("  NewTriggerValue:      " + this.NewTriggerValue)
	D.Log("  HasNewTriggerValue:   " + this.HasNewTriggerValue)
EndFunction




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; list functions


;
; Get the offset in the flattened SliderNameList array for SliderSet number @idxSliderSet.
;
int Function GetSliderNameOffset(int idxSliderSet)
	int offset = 0
	int index = 0
	While (index < idxSliderSet)
		offset += SliderSetList[index].NumberOfSliderNames
		index += 1
	EndWhile
	return offset
EndFunction


;
; Get the offset in the flattened UnequipSlotList array for SliderSet number @idxSliderSet.
;
int Function GetUnequipSlotOffset(int idxSliderSet)
	int offset = 0
	int index = 0
	While (index < idxSliderSet)
		offset += SliderSetList[index].NumberOfUnequipSlots
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
	int overrideOnlyDoctorCanReset = MCM.GetModSettingInt("RadMorphingRedux", "iOnlyDoctorCanReset:Override")
	int overrideIsAdditive = MCM.GetModSettingInt("RadMorphingRedux", "iIsAdditive:Override")
	int overrideHasAdditiveLimit = MCM.GetModSettingInt("RadMorphingRedux", "iHasAdditiveLimit:Override")
	float overrideAdditiveLimit = MCM.GetModSettingFloat("RadMorphingRedux", "fAdditiveLimit:Override") / 100.0
	int overrideUnequipAction = MCM.GetModSettingInt("RadMorphingRedux", "iUnequipAction:Override")
	bool overrideUnequipDropChance = MCM.GetModSettingInt("RadMorphingRedux", "bOverrideUnequipDropChance:Override")
	float overrideUnequipDropChanceValue = MCM.GetModSettingFloat("RadMorphingRedux", "fUnequipDropChance:Override") / 100.0

	; create empty arrays
	If (!SliderSetList)
		SliderSetList = new SliderSet[0]
	EndIf
	If (!SliderNameList)
		SliderNameList = new string[0]
	EndIf
	If (!UnequipSlotList)
		UnequipSlotList = new int[0]
	EndIf
	TriggerNameList = new string[0]

	; create SliderSetList
	int idxSliderSet = 0
	While (idxSliderSet < numberOfSliderSets)
		SliderSet oldSet = None
		If (SliderSetList.Length > idxSliderSet)
			oldSet = SliderSetList[idxSliderSet]
		EndIf
		SliderSet newSet = SliderSet_Constructor(idxSliderSet)
		If (TriggerNameList.Find(newSet.TriggerName) == -1)
			TriggerNameList.Add(newSet.TriggerName)
		EndIf
		If (SliderSetList.Length < idxSliderSet + 1)
			SliderSetList.Add(newSet)
		Else
			SliderSetList[idxSliderSet] = newSet
		EndIf

		If (oldSet)
			; keep BaseMorph from existing SliderSet
			newSet.BaseMorph = oldSet.BaseMorph
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
		If (overrideUnequipAction != EOverrideUnequipActionNoOverride)
			If (overrideUnequipAction == EOverrideUnequipActionUnequip)
				newSet.UnequipAction = EUnequipActionUnequip
			ElseIf (overrideUnequipAction == EOverrideUnequipActionDrop)
				newSet.UnequipAction = EUnequipActionDrop
			ElseIf (overrideUnequipAction == EOverrideUnequipActionDestroy)
				newSet.UnequipAction = EUnequipActionDestroy
			EndIf
		EndIf
		If (overrideUnequipDropChance)
			newSet.UnequipDropChance = overrideUnequipDropChanceValue
		EndIf

		; populate flattened arrays
		int sliderNameOffset = GetSliderNameOffset(idxSliderSet)
		If (newSet.IsUsed)
			string[] names = Util.StringSplit(newSet.SliderName, "|")
			int idxSlider = 0
			While (idxSlider < newset.NumberOfSliderNames)
				int currentIdx = sliderNameOffset + idxSlider
				If (SliderNameList.Length < currentIdx + 1)
					SliderNameList.Add(names[idxSlider])
				ElseIf (!oldSet || idxSlider >= oldSet.NumberOfSliderNames)
					; insert into array
					SliderNameList.Insert(names[idxSlider], currentIdx)
				Else
					; replace item
					SliderNameList[currentIdx] = names[idxSlider]
				EndIf
				idxSlider += 1
			EndWhile
		EndIf

		; remove unused items
		If (oldSet && newSet.NumberOfSliderNames < oldSet.NumberOfSliderNames)
			SliderNameList.Remove(sliderNameOffset + newSet.NumberOfSliderNames, oldset.NumberOfSliderNames - newset.NumberOfSliderNames)
		EndIf

		int uneqipSlotOffset = GetUnequipSlotOffset(idxSliderSet)
		If (newSet.IsUsed && newset.NumberOfUnequipSlots > 0)
			string[] slots = Util.StringSplit(newSet.UnequipSlot, "|")
			int idxSlot = 0
			While (idxSlot < newset.NumberOfUnequipSlots)
				int currentIdx = uneqipSlotOffset + idxSlot
				If (UnequipSlotList.Length < currentIdx + 1)
					UnequipSlotList.Add(slots[idxSlot] as int)
				ElseIf (!oldSet || idxSlot >= oldSet.NumberOfUnequipSlots)
					; insert into array
					UnequipSlotList.Insert(slots[idxSlot] as int, currentIdx)
				Else
					; replace item
					UnequipSlotList[currentIdx] = slots[idxSlot] as int
				EndIf
				idxSlot += 1
			EndWhile
		EndIf

		; remove unused items
		If (oldSet && newSet.NumberOfUnequipSlots < oldSet.NumberOfUnequipSlots)
			UnequipSlotList.Remove(uneqipSlotOffset + newSet.NumberOfUnequipSlots, oldset.NumberOfUnequipSlots - newset.NumberOfUnequipSlots)
		EndIf

		idxSliderSet += 1
	EndWhile

	D.Log("  Sliders:      " + SliderNameList)
	D.Log("  UnequipSlotList: " + UnequipSlotList)
EndFunction


;
; Update the value of a morph trigger.
;
Function SetTriggerValue(string triggerName, float value)
	D.Log("SliderSet.SetTriggerValue: " + triggerName + " = " + value)
	int idxSliderSet = 0
	While (idxSliderSet < SliderSetList.Length)
		SliderSet_SetTriggerValue(idxSliderSet, triggerName, value)
		idxSliderSet += 1
	EndWhile
EndFunction


;
; Get the list of morph updates (sliderName:newValue) for all SliderSetList with @updateType.
;
CumulativeMorphUpdate[] Function CalculateMorphUpdates(int updateType)
	MorphUpdate[] updates = new MorphUpdate[0]
	int idxSliderSet = 0
	While (idxSliderSet < SliderSetList.Length)
		SliderSet sliderSet = SliderSetList[idxSliderSet]
		If (sliderSet.UpdateType == updateType)
			MorphUpdate[] sliderSetUpdates = SliderSet_CalculateMorphUpdates(idxSliderSet)
			int idxUpdate = 0
			While (idxUpdate < sliderSetUpdates.Length)
				MorphUpdate update = sliderSetUpdates[idxUpdate]
				updates.Add(update)
				idxUpdate += 1
			EndWhile
		EndIf
		idxSliderSet += 1
	EndWhile

	return CalculateCumulativeMorphs(updates)
EndFunction


;
; Get the total (max) percentage of morphs (base + current) currently applied for all SliderSetList.
; Relative to lower and upper threshold.
; 
; When SliderSet.TargetMorph has been reached, morph percentage is 100% (=1.0).
; With additive morphing the value may go above 100%.
;
; @param onlyPermanent - only include slider sets with permanent / only doctor morphs
;
float Function GetMorphPercentage(bool onlyPermanent=false)
	float morph = 0.0
	int idxTrigger = 0
	While (idxTrigger < TriggerNameList.Length)
		string triggerName = TriggerNameList[idxTrigger]
		morph = Math.max(Math.Max(morph, GetMorphPercentageForTrigger(triggerName, false, onlyPermanent)), GetMorphPercentageForTrigger(triggerName, true, onlyPermanent))
		idxTrigger += 1
	EndWhile
	return morph
EndFunction

;
; Get the amount of base morphs (permanent morphs) for all SliderSetList.
;
float Function GetBaseMorphPercentage()
	float morph = 0.0
	int idxTrigger = 0
	While (idxTrigger < TriggerNameList.Length)
		string triggerName = TriggerNameList[idxTrigger]
		morph = Math.max(Math.Max(morph, GetBaseMorphPercentageForTrigger(triggerName, false)), GetBaseMorphPercentageForTrigger(triggerName, true))
		idxTrigger += 1
	EndWhile
	return morph
EndFunction


;
; Get the total (max) percentage of morphs (base + current) for a specific trigger name.
; Relative to the minimum lower threshold and maximum upper threshold across all relevant slider sets.
;
; @param triggerName - the trigger's name
; @param inverted
;    - true: only check slider sets that invert the trigger value
;    - false: only check slider sets that don't invert the trigger value
; @param onlyPermanent - only include slider sets with permanent / only doctor morphs
;
float Function GetMorphPercentageForTrigger(string triggerName, bool inverted, bool onlyPermanent=false)
	float thresholdMin = 1.0
	float thresholdMax = 0.0
	float morph = 0.0

	; determine the range for this trigger
	int idxSliderSet = 0
	While (idxSliderSet < SliderSetList.Length)
		SliderSet item = SliderSetList[idxSliderSet]
		If ((!onlyPermanent || item.OnlyDoctorCanReset) && item.TriggerName == triggerName && item.InvertTriggerValue == inverted)
			thresholdMin = Math.Min(thresholdMin, item.ThresholdMin)
			thresholdMax = Math.Max(thresholdMax, item.ThresholdMax)
		EndIf
		idxSliderSet += 1
	EndWhile

	; find the max value for this trigger
	If (thresholdMin < thresholdMax)
		idxSliderSet = 0
		While (idxSliderSet < SliderSetList.Length)
			SliderSet item = SliderSetList[idxSliderSet]
			If (item.TriggerName == triggerName && item.InvertTriggerValue == inverted && item.FullMorph > 0)
				float lowerOffset = item.ThresholdMin - thresholdMin
				float upperOffset = thresholdMax - item.ThresholdMax
				float range = 1.0 - lowerOffset - upperOffset
				float value = item.FullMorph * range + lowerOffset
				morph = Math.max(morph, value)
			EndIf
			idxSliderSet += 1
		EndWhile
	EndIf
	return morph
EndFunction


;
; Get the total (max) percentage of base morphs (permanent morphs) for a specific trigger name.
; Relative to the minimum lower threshold and maximum upper threshold across all relevant slider sets.
;
; @param triggerName - the trigger's name
; @param inverted
;    - true: only check slider sets that invert the trigger value
;    - false: only check slider sets that don't invert the trigger value
;
float Function GetBaseMorphPercentageForTrigger(string triggerName, bool inverted)
	float thresholdMin = 1.0
	float thresholdMax = 0.0
	float morph = 0.0

	; determine the range for this trigger
	int idxSliderSet = 0
	While (idxSliderSet < SliderSetList.Length)
		SliderSet item = SliderSetList[idxSliderSet]
		If (item.TriggerName == triggerName && item.InvertTriggerValue == inverted)
			thresholdMin = Math.Min(thresholdMin, item.ThresholdMin)
			thresholdMax = Math.Max(thresholdMax, item.ThresholdMax)
		EndIf
		idxSliderSet += 1
	EndWhile

	; find the max value for this trigger
	If (thresholdMin < thresholdMax)
		idxSliderSet = 0
		While (idxSliderSet < SliderSetList.Length)
			SliderSet item = SliderSetList[idxSliderSet]
			If (item.TriggerName == triggerName && item.InvertTriggerValue == inverted && item.FullMorph > 0)
				float lowerOffset = item.ThresholdMin - thresholdMin
				float upperOffset = thresholdMax - item.ThresholdMax
				float range = 1.0 - lowerOffset - upperOffset
				float value = item.BaseMorph * range + lowerOffset
				morph = Math.max(morph, value)
			EndIf
			idxSliderSet += 1
		EndWhile
	EndIf
	return morph
EndFunction


;
; Remove the BaseMorph for all SliderSetList.
;
Function ClearBaseMorphs()
	MorphUpdate[] updates = new MorphUpdate[0]
	int idxSliderSet = 0
	While (idxSliderSet < SliderSetList.Length)
		SliderSet_ClearBaseMorph(idxSliderSet)
		idxSliderSet += 1
	EndWhile
EndFunction


;
; Reduce all base morphs to a percentage (0.0-1.0) relative to the total range of each trigger.
;
; @param float targetBaseMorph - target base morph percentage (0.0-1.0) relative to the total range of each trigger.
; @returns MorphUpdate[] - list of morph updates to apply the new base morphs.
;
CumulativeMorphUpdate[] Function ReduceBaseMorphs(float targetBaseMorph)
	D.Log("SliderSet.ReduceBaseMorphs: " + targetBaseMorph)
	int idxTrigger = 0
	MorphUpdate[] updates = new MorphUpdate[0]
	While (idxTrigger < TriggerNameList.Length)
		string triggerName = TriggerNameList[idxTrigger]
		MorphUpdate[] triggerUpdates = ReduceBaseMorphsForTrigger(triggerName, false, targetBaseMorph)
		int idxUpdate = 0
		While (idxUpdate < triggerUpdates.Length)
			MorphUpdate update = triggerUpdates[idxUpdate]
			updates.Add(update)
			idxUpdate += 1
		EndWhile
		triggerUpdates = ReduceBaseMorphsForTrigger(triggerName, true, targetBaseMorph)
		idxUpdate = 0
		While (idxUpdate < triggerUpdates.Length)
			MorphUpdate update = triggerUpdates[idxUpdate]
			updates.Add(update)
			idxUpdate += 1
		EndWhile
		idxTrigger += 1
	EndWhile

	return CalculateCumulativeMorphs(updates)
EndFunction

;
; Reduce all base morphs for this trigger to a percentage (0.0-1.0) relative to the total range of each trigger.
;
; @param string triggerName - the trigger's name
; @param bool inverted
;    - true: only check slider sets that invert the trigger value
;    - false: only check slider sets that don't invert the trigger value
; @param float targetBaseMorph - target base morph percentage (0.0-1.0) relative to the total range of each trigger.
; @returns MorphUpdate[] - list of morph updates to apply the new base morphs.
;
MorphUpdate[] Function ReduceBaseMorphsForTrigger(string triggerName, bool inverted, float targetBaseMorph)
	D.Log("ReduceBaseMorphsForTrigger: " + triggerName + ", " + inverted + ", " + targetBaseMorph)
	float thresholdMin = 1.0
	float thresholdMax = 0.0
	MorphUpdate[] updates = new MorphUpdate[0]

	; determine the range for this trigger
	int idxSliderSet = 0
	While (idxSliderSet < SliderSetList.Length)
		SliderSet item = SliderSetList[idxSliderSet]
		If (item.TriggerName == triggerName && item.InvertTriggerValue == inverted)
			thresholdMin = Math.Min(thresholdMin, item.ThresholdMin)
			thresholdMax = Math.Max(thresholdMax, item.ThresholdMax)
		EndIf
		idxSliderSet += 1
	EndWhile

	D.Log("thresholdMin: " + thresholdMin)
	D.Log("thresholdMax: " + thresholdMax)

	; reduce base morphs
	If (thresholdMin < thresholdMax)
		idxSliderSet = 0
		While (idxSliderSet < SliderSetList.Length)
			SliderSet sliderSet = SliderSetList[idxSliderSet]
			D.Log("sliderSet " + idxSliderSet)
			If (sliderSet.TriggerName == triggerName && sliderSet.InvertTriggerValue == inverted && sliderSet.FullMorph > 0)
				float lowerOffset = sliderSet.ThresholdMin - thresholdMin
				float upperOffset = thresholdMax - sliderSet.ThresholdMax
				float range = 1.0 - lowerOffset - upperOffset
				float value = sliderSet.BaseMorph * range + lowerOffset
				D.Log("  lowerOffset: " + lowerOffset)
				D.Log("  upperOffset: " + upperOffset)
				D.Log("  range:       " + range)
				D.Log("  value:       " + value)
				If (value > targetBaseMorph)
					float newBaseMorph = (targetBaseMorph - lowerOffset) / range
					D.Log("  baseMorph: " + sliderSet.BaseMorph + "  ->  " + newBaseMorph)
					sliderSet.BaseMorph = newBaseMorph
					MorphUpdate[] sliderSetUpdates = SliderSet_CalculateFullMorphs(idxSliderSet)
					D.Log("  updates: " + sliderSetUpdates)
					int idxUpdate = 0
					While (idxUpdate < sliderSetUpdates.Length)
						MorphUpdate update = sliderSetUpdates[idxUpdate]
						updates.Add(update)
						idxUpdate += 1
					EndWhile
				EndIf
			EndIf
			idxSliderSet += 1
		EndWhile
	EndIf

	return updates
EndFunction


CumulativeMorphUpdate[] Function CalculateCumulativeMorphs(MorphUpdate[] updates)
	D.Log("SliderSet.CalculateCumulativeMorphs: " + updates)

	; the final list of cumulative updates to be returned
	CumulativeMorphUpdate[] cumUpdates = new CumulativeMorphUpdate[0]

	If (updates.Length == 0)
		D.Log("  no updates")
		return cumUpdates
	EndIf

	; keep track of which slider sets are included in the update list
	bool[] sliderSetChecked = new bool[SliderSetList.Length]
	; keep track of the slider names already in the list of cumulative updates
	string[] sliderNames = new string[0]

	; first loop through the provided update list and populate the list of cumulative updates based only on those
	D.Log("  checking updates")
	int idxUpdate = 0
	While (idxUpdate < updates.Length)
		MorphUpdate update = updates[idxUpdate]
		D.Log("    " + update)
		D.Log("    " + sliderNames)
		CumulativeMorphUpdate cumUpdate = None
		; mark slider set as checked
		sliderSetChecked[update.SliderSetIndex] = true
		; check if the affected slider is already in the list of cumulative updates
		int idxSlider = sliderNames.Find(update.Name)
		If (idxSlider >= 0)
			; if in the list, use the existing cumulative update
			cumUpdate = cumUpdates[idxSlider]
			D.Log("      found cumUpdate (" + idxSlider + "): " + cumUpdate)
		Else
			; if not in the list, create a new cumulative update
			D.Log("      new cumUpdate")
			sliderNames.Add(update.Name)
			cumUpdate = new CumulativeMorphUpdate
			cumUpdate.Name = update.Name
			cumUpdate.ApplyPlayerFemale = false
			cumUpdate.ApplyPlayerMale = false
			cumUpdate.ApplyCompanionFemale = false
			cumUpdate.ApplyCompanionMale = false
			cumUpdate.PlayerFemaleValue = 0.0
			cumUpdate.PlayerMaleValue = 0.0
			cumUpdate.CompanionFemaleValue = 0.0
			cumUpdate.CompanionMaleValue = 0.0
			cumUpdates.Add(cumUpdate)
		EndIf
		; update who it applies to and the values
		If (update.ApplyPlayer && update.ApplyFemale)
			cumUpdate.ApplyPlayerFemale = true
			cumUpdate.PlayerFemaleValue += update.Value
		EndIf
		If (update.ApplyPlayer && update.ApplyMale)
			cumUpdate.ApplyPlayerMale = true
			cumUpdate.PlayerMaleValue += update.Value
		EndIf
		If (update.ApplyCompanion && update.ApplyFemale)
			cumUpdate.ApplyCompanionFemale = true
			cumUpdate.CompanionFemaleValue += update.Value
		EndIf
		If (update.ApplyCompanion && update.ApplyMale)
			cumUpdate.ApplyCompanionMale = true
			cumUpdate.CompanionMaleValue += update.Value
		EndIf
		D.Log("        -> " + cumUpdate)
		idxUpdate += 1
	EndWhile
	D.Log("    -> " + cumUpdates)

	D.Log("  checking other slider sets")
	; after going through the provided update list, check the remaining slider sets
	int idxSliderSet = 0
	While (idxSliderSet < SliderSetList.Length)
		; check that the slider set was not already in the list of updates
		If (!sliderSetChecked[idxSliderSet])
			If (SliderSetList[idxSliderSet].IsUsed)
				D.Log("    SliderSet " + idxSliderSet + ": checking now")
				; loop through that slider set's morphs
				MorphUpdate[] sliderSetMorphs = SliderSet_GetFullMorphs(idxSliderSet)
				int idxSliderSetMorph = 0
				While (idxSliderSetMorph < sliderSetMorphs.Length)
					MorphUpdate sliderSetMorph = sliderSetMorphs[idxSliderSetMorph]
					D.Log("      " + sliderSetMorph)
					; check if the slider is affected by the update
					int idxSlider = sliderNames.Find(sliderSetMorph.Name)
					If (idxSlider >= 0)
						CumulativeMorphUpdate cumUpdate = cumUpdates[idxSlider]
						D.Log("        add to cumUpdate: " + cumUpdate)
						; update the values
						If (cumUpdate.ApplyPlayerFemale && sliderSetMorph.ApplyPlayer && sliderSetMorph.ApplyFemale)
							cumUpdate.PlayerFemaleValue += sliderSetMorph.Value
						EndIf
						If (cumUpdate.ApplyPlayerMale && sliderSetMorph.ApplyPlayer && sliderSetMorph.ApplyMale)
							cumUpdate.PlayerMaleValue += sliderSetMorph.Value
						EndIf
						If (cumUpdate.ApplyCompanionFemale && sliderSetMorph.ApplyCompanion && sliderSetMorph.ApplyFemale)
							cumUpdate.CompanionFemaleValue += sliderSetMorph.Value
						EndIf
						If (cumUpdate.ApplyCompanionMale && sliderSetMorph.ApplyCompanion && sliderSetMorph.ApplyMale)
							cumUpdate.CompanionMaleValue += sliderSetMorph.Value
						EndIf
						D.Log("         -> " + cumUpdate)
					Else
						D.Log("        slider not affected by update: " + sliderSetMorph.Name)
					EndIf
					idxSliderSetMorph += 1
				EndWhile
			EndIf
		Else
			D.Log("    SliderSet " + idxSliderSet + ": already checked")
		EndIf
		idxSliderSet += 1
	EndWhile
	D.Log("  -> " + cumUpdates)
	return cumUpdates
EndFunction


;
; Get the list of full morphs based on a CurrentMorph and BaseMorph for all slider sets.
;
CumulativeMorphUpdate[] Function CalculateFullMorphs()
	MorphUpdate[] updates = new MorphUpdate[0]
	int idxSliderSet = 0
	While (idxSliderSet < SliderSetList.Length)
		MorphUpdate[] sliderSetUpdates = SliderSet_CalculateFullMorphs(idxSliderSet)
		int idxUpdate = 0
		While (idxUpdate < sliderSetUpdates.Length)
			MorphUpdate update = sliderSetUpdates[idxUpdate]
			updates.Add(update)
			idxUpdate += 1
		EndWhile
		idxSliderSet += 1
	EndWhile

	return CalculateCumulativeMorphs(updates)
EndFunction


;
; Check whether a slider set with OnlyDoctorCanReset exists.
;
bool Function HasDoctorOnly()
	int idxSliderSet = 0
	While (idxSliderSet < SliderSetList.Length)
		SliderSet sliderSet = SliderSetList[idxSliderSet]
		If (sliderSet.IsUsed && (sliderSet.OnlyDoctorCanReset || sliderSet.UpdateType == EUpdateTypeOnSleep))
			return true
		EndIf
		idxSliderSet += 1
	EndWhile
	return false
EndFunction


;
; Get the list of slots that need to be unequipped due to morphs.
;
UnequipSlot[] Function GetUnequipSlots()
	D.Log("GetUnequipSlots " + UnequipSlotList)
	UnequipSlot[] slots = new UnequipSlot[0]
	int idxSliderSet = 0
	While (idxSliderSet < SliderSetList.Length)
		SliderSet sliderSet = SliderSetList[idxSliderSet]
		D.Log("  (SliderSet " + idxSliderSet + ") " + sliderSet.FullMorph + " > " + sliderSet.ThresholdUnequip + "  ?")
		If (sliderSet.FullMorph > sliderSet.ThresholdUnequip)
			D.Log("    YES")
			int offset = GetUnequipSlotOffset(idxSliderSet)
			D.Log("    Offset: " + offset)
			int idxSlot = 0
			While (idxSlot < sliderSet.NumberOfUnequipSlots)
				UnequipSlot slot = new UnequipSlot
				slot.Slot = UnequipSlotList[idxSlot + offset]
				slot.ApplyPlayer = sliderSet.ApplyTo == EApplyToAll || sliderSet.ApplyTo == EApplyToPlayer
				slot.ApplyCompanion = sliderSet.ApplyTo == EApplyToAll || sliderSet.ApplyTo == EApplyToCompanion
				slot.ApplyFemale = sliderSet.Sex == EApplySexAll || sliderSet.Sex == EApplySexFemale
				slot.ApplyMale = sliderSet.Sex == EApplySexAll || sliderSet.Sex == EApplySexMale
				slot.Drop = sliderSet.UnequipAction == EUnequipActionDrop
				slot.Destroy = sliderSet.UnequipAction == EUnequipActionDestroy
				slot.DropChance = sliderSet.UnequipDropChance
				slots.Add(slot)
				idxSlot += 1
				D.Log(slot)
			EndWhile
		EndIf
		idxSliderSet += 1
	EndWhile
	return slots
EndFunction