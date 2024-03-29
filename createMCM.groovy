import groovy.json.*

JsonSlurper slurper = new JsonSlurper()
JsonOutput builder = new JsonOutput()

// FOMOD options for number of sliders
XmlSlurper xml = new XmlSlurper()
def fomod = xml.parse(new File(".fomod/fomod/ModuleConfig.xml"))
def counts = fomod
		.installSteps
		.installStep
		.find{it.@name=="MCM Layout"}
		.optionalFileGroups
		.group
		.plugins
		.plugin
		.@name
		*.toString()
		*.substring(13)
		*.toInteger()



// json templates
def headerText = new File("MCM/config/RadMorphingRedux/config.header.tpl.json").text
def tplText = new File("MCM/config/RadMorphingRedux/config.tpl.json").text.replaceAll(~/"\{\{TPL:HEADER\}\}"/, headerText)
def tplSliderPageText = new File("MCM/config/RadMorphingRedux/config.sliderSet.page.tpl.json").text.replaceAll(~/"\{\{TPL:HEADER\}\}"/, headerText)
def tplSliderText = new File("MCM/config/RadMorphingRedux/config.sliderSet.tpl.json").text.replaceAll(~/"\{\{TPL:HEADER\}\}"/, headerText)


def equippedText = (0..61).collect{idx->
	"""
				{
					"text": "",
					"type": "textinput",
					"id": "sSlot${idx}:EquippedItems",
					"valueOptions": {
						"sourceType": "ModSettingString"
					}
				}"""
}.join(',')
tplText = tplText.replaceAll(~/"\{\{TPL:EQUIPPED_ITEMS\}\}"/, equippedText)

// old ini
def oldVarsMatched = new File("MCM/config/RadMorphingRedux/settings.ini").text =~ /(?:\[([^\]\r\n]+)\])|(?:([^;=\r\n]+?)=([^;\r\n]*?)(?:\s*[;\r\n]))/
def oldVars = [:]
def curSection
oldVarsMatched.each{oldVar ->
	if (oldVar[1]) {
		if (oldVar[1] == 'Slider0' || !(oldVar[1] ==~ /Slider\d+/)) {
			curSection = oldVar[1]
			oldVars[curSection] = [:]
		} else {
			curSection = null
		}
	} else if (curSection && oldVar[2]) {
		oldVars[curSection][oldVar[2]] = oldVar[3]
	}
}


def replacer
replacer = {json ->
	if (json instanceof Map) {
		def remove = []
		def add = [:]
		json.each{k,v->
			if (k ==~ /^(.+)--join\(([^\)]+)\)$/ && v instanceof List) {
				def nk = k.replaceAll(/^(.+)--join\(([^\)]+)\)$/, '$1')
				def nv = v.join(k.replaceAll(/^(.+)--join\(([^\)]+)\)$/, '$2'))
				remove << k
				add[nk] = nv
			} else {
				json[k] = replacer(json[k])
			}
		}
		json.removeAll{rk,kv->remove.contains(rk)}
		json += add
	} else if (json instanceof List) {
		json.eachWithIndex{child,idx->json[idx]=replacer(child)}
	}
	return json
}


// create json and ini files
counts.eachWithIndex{count, idxCount ->
	// json
	def tpl = slurper.parseText(tplText)
	count.times{idx->
		def page = slurper.parseText(tplSliderPageText.replaceAll(~/\{\{idxLbl\}\}/, "${idx + 1}").replaceAll(~/\{\{idx\}\}/, "${idx}"))
		page.content += slurper.parseText(tplSliderText.replaceAll(~/\{\{idxLbl\}\}/, "${idx + 1}").replaceAll(~/\{\{idx\}\}/, "${idx}"))
		tpl.pages << page
	}
	tpl = replacer(tpl)
	new File(".options/mcm_SliderSets_${count}/MCM/config/RadMorphingRedux").mkdirs()
	File output = new File(".options/mcm_SliderSets_${count}/MCM/config/RadMorphingRedux/config.json")
	output.text = builder.prettyPrint(builder.toJson(tpl))

	// ini
	def newVarsMatched = output.text =~ /"id"\s*:\s*"([^"]+?)(?::([^"]+))?"/
	def newVars = ["Static":["iNumberOfSliderSets":count]]
	count.times{idx->
		newVars["Slider${idx}"] = ["sTriggerName":""]
	}
	newVarsMatched.each{newVar ->
		def section = newVar[2]
		if (section) {
			if (!newVars[section]) {
				newVars[section] = [:]
			}
			newVars[section][newVar[1]] = oldVars.getAt(section ==~ /Slider\d+/ ? 'Slider0' : section)?.getAt(newVar[1])
		}
	}
	StringBuilder sb = new StringBuilder()
	newVars.each{section, vars ->
		sb << "\n\n\n[${section}]\n"
		vars.each{name, val ->
			sb << "${name}=${val}\n"
		}
	}
	File ini = new File(".options/mcm_SliderSets_${count}/MCM/config/RadMorphingRedux/settings.ini")
	ini.text = sb

	// first option is used as default
	if (idxCount == 0) {
		File outputDefault = new File("MCM/config/RadMorphingRedux/config.json")
		outputDefault.text = output.text
		File iniDefault = new File("MCM/config/RadMorphingRedux/settings.ini")
		iniDefault.text = ini.text
	}
}