	object_const_def
	const TOHJOFALLS_ROCK1
	const TOHJOFALLS_ROCK2
	const TOHJOFALLS_ROCK3
	const TOHJOFALLS_ROCK4
	const TOHJOFALLS_POKE_BALL

TohjoFalls_MapScripts:
	def_scene_scripts

	def_callbacks

TohjoFallsRock:
	jumpstd SmashRockScript

TohjoFallsMoonStone:
	itemball MOON_STONE

TohjoFalls_MapEvents:
	db 0, 0 ; filler

	def_warp_events
	warp_event  7, 31, ROUTE_27, 2
	warp_event 25,  3, ROUTE_26, 3
	warp_event 35, 17, ROUTE_26, 4

	def_coord_events

	def_bg_events

	def_object_events
	object_event 33, 16, SPRITE_ROCK, SPRITEMOVEDATA_SMASHABLE_ROCK, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, Route40Rock, -1
	object_event  9, 11, SPRITE_ROCK, SPRITEMOVEDATA_SMASHABLE_ROCK, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, Route40Rock, -1
	object_event 32,  4, SPRITE_ROCK, SPRITEMOVEDATA_SMASHABLE_ROCK, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, Route40Rock, -1
	object_event 27,  3, SPRITE_ROCK, SPRITEMOVEDATA_SMASHABLE_ROCK, 0, 0, -1, -1, 0, OBJECTTYPE_SCRIPT, 0, Route40Rock, -1
	object_event 10, 10, SPRITE_POKE_BALL, SPRITEMOVEDATA_STILL, 0, 0, -1, -1, 0, OBJECTTYPE_ITEMBALL, 0, TohjoFallsMoonStone, EVENT_TOHJO_FALLS_MOON_STONE
