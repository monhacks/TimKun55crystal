	db PRIMEAPE ; 057

	db  65, 105,  60,  95,  60,  70
	evs  0,   2,   0,   0,   0,   0
	;   hp  atk  def  spd  sat  sdf

	db FIGHTING, FIGHTING ; type
	db 75 ; catch rate
	db 149 ; base exp
	db NO_ITEM, NO_ITEM ; items
	db GENDER_F50 ; gender ratio
	db 2 ; step cycles to hatch
	INCBIN "gfx/pokemon/primeape/front.dimensions"
	dw NULL, NULL ; unused (beta front/back pics)
	db GROWTH_MEDIUM_FAST ; growth rate
	dn EGG_GROUND, EGG_GROUND ; egg groups

	; tm/hm learnset
	tmhm DYNAMICPUNCH, HEADBUTT, CURSE, TOXIC, ROCK_SMASH, PSYCH_UP, HIDDEN_POWER, SNORE, HYPER_BEAM, PROTECT, ENDURE, ROCK_TOMB, IRON_TAIL, THUNDER, RETURN, DIG, MUD_SLAP, DOUBLE_TEAM, ICE_PUNCH, SWAGGER, SLEEP_TALK, AERIAL_ACE, SWIFT, DEFENSE_CURL, THUNDERPUNCH, REST, ATTRACT, THIEF, FIRE_PUNCH, BODY_SLAM, BULLDOZE, STRENGTH, THUNDERBOLT, POISON_JAB, STONE_EDGE, GUNK_SHOT, ACROBATICS, DRAIN_PUNCH, FOCUS_BLAST, GROWTH_PUNCH, ROCK_TOMB, GIGA_IMPACT, SUNNY_DAY
	; end
