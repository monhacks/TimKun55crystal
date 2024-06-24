	object_const_def
	const CIANWOODBEASTSHOUSE_GRANNY
	const CIANWOODBEASTSHOUSE_ENTEI_STATUE
	const CIANWOODBEASTSHOUSE_RAIKOU_STATUE

CianwoodBeastsHouse_MapScripts:
	def_scene_scripts

	def_callbacks

BeastHouseGrannyScript:
	faceplayer
	opentext
	writetext GrannyBeastsText
	waitbutton
	closetext
	end
	
RaikouStatueScript:
	opentext
	writetext StatueText
	waitbutton
	setval RAIKOU
	special ShowPokedexEntry
	closetext
	end

EnteiStatueScript:
	opentext
	writetext StatueText
	waitbutton
	setval ENTEI
	special ShowPokedexEntry
	closetext
	end
	
GrannyBeastsText:
	text "Hello, dear."
	line "I don't get many"
	cont "visitors out here."
	
	para "Do you know about"
	line "JOHTO'S LEGENDARY"
	cont "BEASTS?"
	
	para "Years ago when I"
	line "was a young girl"
	cont "on my journey, I"
	
	para "encountered both"
	line "RAIKOU and ENTEI."
	
	para "To witness such"
	line "amazing creatures"
	cont "up close, it was"
	
	para "scary, but the"
	line "highlight of my"
	cont "journey."
	
	para "I've spent years"
	line "trying to create"
	cont "monuments that"
	
	para "truly represent"
	line "their majesty!"
	
	para "Please, check"
	line "them out!"
	done
	
StatueText:
	text "It's a very"
	line "realistic and"
	cont "detailed statue!"
	done

CianwoodBeastsHouse_MapEvents:
	db 0, 0 ; filler

	def_warp_events
	warp_event  2,  7, CIANWOOD_CITY, 7
	warp_event  3,  7, CIANWOOD_CITY, 7

	def_coord_events

	def_bg_events

	def_object_events
	object_event  2,  3, SPRITE_GRANNY, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_RED, OBJECTTYPE_SCRIPT, 0, BeastHouseGrannyScript, -1
	object_event  3,  1, SPRITE_RAIKOU, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_EMOTE, OBJECTTYPE_SCRIPT, 0, RaikouStatueScript, -1
	object_event  4,  1, SPRITE_ENTEI, SPRITEMOVEDATA_STANDING_DOWN, 0, 0, -1, -1, PAL_NPC_EMOTE, OBJECTTYPE_SCRIPT, 0, EnteiStatueScript, -1
