Scriptname LenARM:LenARM_SliderSet extends Quest
{Contains SliderSet struct and relevant logic.}

Group LenARM
	LenARM_Debug Property D Auto Const
	LenARM_Util Property Util Auto Const
EndGroup

Group EnumApplyCompanion
	int Property EApplyCompanionNone = 0 Auto Const
	int Property EApplyCompanionFemale = 1 Auto Const
	int Property EApplyCompanionMale = 2 Auto Const
	int Property EApplyCompanionAll = 3 Auto Const
EndGroup




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; SliderSet definition

Struct SliderSet
	bool IsUsed
	{TRUE if this SliderSet has been set up through MCM}


	;
	; MCM values
	;
	string SliderName
	{name of the sliders to morph, multiple sliders are separated by "|"}

	string TriggerName
	{name of the trigger value that is used to determine morphing}
	
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
	int NumberOfUnequipSlots

	float BaseMorph
	float CurrentMorph
EndStruct




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; instances

SliderSet[] SliderSets
{the slider sets}

string[] SliderNames
{flattened two-dimensional array[idxSliderSet][idxSliderName]}

string[] UnequipSlots
{flattened two-dimensional array[idxSliderSet][idxSlotName]}

float[] OriginalMorphs
{flattened two-dimensional array[idxSliderSet][idxSliderName]}

float[] OriginalCompanionMorphs
{flattened three-dimensional array[idxCompanion][idxSliderSet][idxSliderName]}

Actor[] Companions
{list of companions with saved original morphs}




;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------
; methods

SliderSet Function Constructor(int idxSliderSet)
	{creates a new SliderSet with the MCM values for SliderSet number @idxSliderSet}
	D.Log("SliderSet Constructor: " + idxSliderSet)
	SliderSet set = new SliderSet
	set.SliderName = MCM.GetModSettingString("LenA_RadMorphing", "sSliderName:Slider" + idxSliderSet)
	If (set.SliderName != "")
		set.IsUsed = true
		set.TriggerName = MCM.GetModSettingString("LenA_RadMorphing", "sTriggerName:Slider" + idxSliderSet)
		set.TargetMorph = MCM.GetModSettingFloat("LenA_RadMorphing", "fTargetMorph:Slider" + idxSliderSet) / 100.0
		set.ThresholdMin = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdMin:Slider" + idxSliderSet) / 100.0
		set.ThresholdMax = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdMax:Slider" + idxSliderSet) / 100.0
		set.UnequipSlot = MCM.GetModSettingString("LenA_RadMorphing", "sUnequipSlot:Slider" + idxSliderSet)
		set.ThresholdUnequip = MCM.GetModSettingFloat("LenA_RadMorphing", "fThresholdUnequip:Slider" + idxSliderSet) / 100.0
		set.ApplyCompanion = MCM.GetModSettingInt("LenA_RadMorphing", "iApplyCompanion:Slider" + idxSliderSet)
		set.OnlyDoctorCanReset = MCM.GetModSettingBool("LenA_RadMorphing", "bOnlyDoctorCanReset:Slider" + idxSliderSet)
		set.IsAdditive = MCM.GetModSettingBool("LenA_RadMorphing", "bIsAdditive:Slider" + idxSliderSet)
		set.HasAdditiveLimit = MCM.GetModSettingBool("LenA_RadMorphing", "bHasAdditiveLimit:Slider" + idxSliderSet)
		set.AdditiveLimit = MCM.GetModSettingFloat("LenA_RadMorphing", "fAdditiveLimit:Slider" + idxSliderSet) / 100.0

		string[] names = Util.StringSplit(set.SliderName, "|")
		set.NumberOfSliderNames = names.Length

		If (set.UnequipSlot != "")
			string[] slots = Util.StringSplit(set.UnequipSlot, "|")
			set.NumberOfUnequipSlots = slots.Length
		Else
			set.NumberOfUnequipSlots = 0
		EndIf
	Else
		set.IsUsed = false
	EndIf

	D.Log(set)
	return set
EndFunction


int Function GetSliderNameOffset(int idxSliderSet)
	{gets the offset in the flattened SliderNames array for SliderSet number @idxSliderSet}
	int offset = 0
	int index = 0
	While (index < idxSliderSet)
		offset += SliderSets[index].NumberOfSliderNames
		index += 1
	EndWhile
	return offset
EndFunction


int Function GetUnequipSlotOffset(int idxSliderSet)
	{gets the offset in the flattened UnequipSlots array for SliderSet number @idxSliderSet}
	int offset = 0
	int index = 0
	While (index < idxSliderSet)
		offset += SliderSets[index].NumberOfUnequipSlots
		index += 1
	EndWhile
	return offset
EndFunction


Function LoadSliderSets(int numberOfSliderSets, Actor player)
	D.Log("LoadSliderSets")
	; create empty arrays
	If (!SliderSets)
		SliderSets = new SliderSet[0]
	EndIf
	If (!SliderNames)
		SliderNames = new string[0]
	EndIf
	If (!UnequipSlots)
		UnequipSlots = new string[0]
	EndIf
	If (!OriginalMorphs)
		OriginalMorphs = new float[0]
	EndIf
	If (!OriginalCompanionMorphs)
		OriginalCompanionMorphs = new float[0]
	EndIf

	; create SliderSets
	int idxSliderSet = 0
	While (idxSliderSet < numberOfSliderSets)
		SliderSet oldSet = SliderSets[idxSliderSet]
		SliderSet newSet = Constructor(idxSliderSet)
		SliderSets[idxSliderSet] = newSet

		If (oldSet)
			; keep BaseMorph and CurrentMorph from existing SliderSet
			newSet.BaseMorph = oldSet.BaseMorph
			newset.CurrentMorph = oldSet.CurrentMorph
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
					SliderNames.Insert(names[idxSlider], currentIdx)
					OriginalMorphs.Insert(morph, currentIdx)
				Else
					; replace item
					SliderNames[currentIdx] = names[idxSlider]
					OriginalMorphs[currentIdx] = morph
				EndIf
				idxSlider += 1
			EndWhile
		EndIf

		; remove unused items
		If (oldSet && newSet.NumberOfSliderNames < oldSet.NumberOfSliderNames)
			SliderNames.Remove(sliderNameOffset + newSet.NumberOfSliderNames, oldset.NumberOfSliderNames - newset.NumberOfSliderNames)
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

	D.Log("  SliderSets:     " + SliderSets)
	D.Log("  SliderNames:    " + SliderNames)
	D.Log("  OriginalMorphs: " + OriginalMorphs)
	D.Log("  UnequipSlots:   " + UnequipSlots)
EndFunction