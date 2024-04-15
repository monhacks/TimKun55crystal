SaveMenu:
	call LoadStandardMenuHeader
	farcall DisplaySaveInfoOnSave
	call SpeechTextbox
	call UpdateSprites
	farcall SaveMenu_CopyTilemapAtOnce
	ld hl, WouldYouLikeToSaveTheGameText
	call SaveTheGame_yesorno
	jr nz, .refused
	call AskOverwriteSaveFile
	jr c, .refused
	call PauseGameLogic
	call SavedTheGame
	call ResumeGameLogic
	call ExitMenu
	and a
	ret

.refused
	call ExitMenu
	call GSReloadPalettes
	farcall SaveMenu_CopyTilemapAtOnce
	scf
	ret

SaveAfterLinkTrade:
	call PauseGameLogic
	farcall StageRTCTimeForSave
	farcall BackupMysteryGift
	call SavePokemonData
	call SaveChecksum
	call SaveBackupPokemonData
	call SaveBackupChecksum
	farcall BackupPartyMonMail
	farcall SaveRTC
	call ResumeGameLogic
	ret

Link_SaveGame:
	call AskOverwriteSaveFile
	ret c
ForceGameSave:
	call PauseGameLogic
	call SavedTheGame
	call ResumeGameLogic
	and a
	ret

PauseGameLogic:
	ld a, TRUE
	ld [wGameLogicPaused], a
	ret

ResumeGameLogic:
	xor a ; FALSE
	ld [wGameLogicPaused], a
	ret

AddHallOfFameEntry:
	ld a, BANK(sHallOfFame)
	call OpenSRAM
	ld hl, sHallOfFame + HOF_LENGTH * (NUM_HOF_TEAMS - 1) - 1
	ld de, sHallOfFame + HOF_LENGTH * NUM_HOF_TEAMS - 1
	ld bc, HOF_LENGTH * (NUM_HOF_TEAMS - 1)
.loop
	ld a, [hld]
	ld [de], a
	dec de
	dec bc
	ld a, c
	or b
	jr nz, .loop
	ld hl, wHallOfFamePokemonList
	ld de, sHallOfFame
	ld bc, wHallOfFamePokemonListEnd - wHallOfFamePokemonList + 1
	call CopyBytes
	call CloseSRAM
; This vc_hook causes the Virtual Console to set [sGSBallFlag] and [sGSBallFlagBackup]
; to GS_BALL_AVAILABLE, which enables you to get the GS Ball, take it to Kurt, and
; encounter Celebi. It assumes that sGSBallFlag and sGSBallFlagBackup are at their
; original addresses.
	vc_hook Enable_GS_Ball_mobile_event
	vc_assert BANK(sGSBallFlag) == $1 && sGSBallFlag == $be3c, \
		"sGSBallFlag is no longer located at 01:be3c."
	vc_assert BANK(sGSBallFlagBackup) == $1 && sGSBallFlagBackup == $be44, \
		"sGSBallFlagBackup is no longer located at 01:be44."
	vc_assert GS_BALL_AVAILABLE == $b, \
		"GS_BALL_AVAILABLE is no longer equal to $b."
	ret

AskOverwriteSaveFile:
	ld a, [wSaveFileExists]
	and a
	jr z, .erase
	call CompareLoadedAndSavedPlayerID
	ret z ; pretend the player answered "Yes", but without asking
	ld hl, AnotherSaveFileText
	call SaveTheGame_yesorno
	jr nz, .refused

.erase
	call ErasePreviousSave
	and a
	ret

.refused
	scf
	ret

SaveTheGame_yesorno:
	ld b, BANK(WouldYouLikeToSaveTheGameText)
	call MapTextbox
	call LoadMenuTextbox
	lb bc, 0, 7
	call PlaceYesNoBox
	ld a, [wMenuCursorY]
	dec a
	call CloseWindow
	push af
	call GSReloadPalettes
	pop af
	and a
	ret

CompareLoadedAndSavedPlayerID:
	ld a, BANK(sPlayerData)
	call OpenSRAM
	ld hl, sPlayerData + (wPlayerID - wPlayerData)
	ld a, [hli]
	ld c, [hl]
	ld b, a
	call CloseSRAM
	ld a, [wPlayerID]
	cp b
	ret nz
	ld a, [wPlayerID + 1]
	cp c
	ret

SavedTheGame:
	ld hl, wOptions
	set NO_TEXT_SCROLL, [hl]
	push hl
	ld hl, .saving_text
	call PrintText
	pop hl
	res NO_TEXT_SCROLL, [hl]
	call SaveGameData
	; copy the original text speed setting to the stack
	ld a, [wOptions]
	push af
	; set text speed to fast
	ld a, TEXT_DELAY_FAST
	ld [wOptions], a
	; <PLAYER> saved the game!
	ld hl, SavedTheGameText
	call PrintText
	; restore the original text speed setting
	pop af
	ld [wOptions], a
	ld de, SFX_SAVE
	call WaitPlaySFX
	jp WaitSFX
	
.saving_text
	text "SAVING…"
	done

SaveGameData:
	ld a, TRUE
	ld [wSaveFileExists], a
	farcall StageRTCTimeForSave
	call ValidateSave
	call SaveOptions
	call SavePlayerData
	call SavePokemonData
	ld a, BANK(sBattleTowerChallengeState)
	call OpenSRAM
	ld a, [sBattleTowerChallengeState]
	cp BATTLETOWER_RECEIVED_REWARD
	jr nz, .ok
	xor a
	ld [sBattleTowerChallengeState], a
.ok
	call CloseSRAM

	; At this point, there is no longer any harm in setting this. We can't set
	; it earlier, because it might confuse the load routine into using bad
	; box/mail data, and we can't set it later because we need to set it
	; before our main save copy is valid.
	ld a, 1
	call SetSavePhase

	call SaveChecksum
	call WriteBackupSave
	farcall SaveRTC
	jp CloseSRAM ; just in case

WriteBackupSave:
; Runs after saving the main copy. Writes the "pseudo-WRAM" copies of storage
; and mail, then creates the backup save. This process is automatically run
; on game load if we have a valid main save but not a backup save.
	; Save storage, mail, mobile event and mystery gift to backup
	farcall BackupPartyMonMail
	farcall BackupGSBallFlag
	farcall BackupMysteryGift
	call SaveStorageSystem

	; Save the backup copy of game data.
	call ValidateBackupSave
	call SaveBackupOptions
	call SaveBackupPlayerData
	call SaveBackupPokemonData
	call SaveBackupChecksum

	; Finished saving.
	xor a
	call SetSavePhase
	jp CloseSRAM

LoadStorageSystem:
; Copy backup storage system to active.
	ld hl, sBackupNewBox1
	ld de, sNewBox1
	call CopyStorageSystem

	; Initialize allocation information.
	newfarjp FlushStorageSystem

SaveStorageSystem:
; Copy active storage system to backup.
	ld hl, sNewBox1
	ld de, sBackupNewBox1
	; fallthrough
CopyStorageSystem:
	ld a, BANK(sNewBox1)
	call OpenSRAM
	ld bc, sNewBoxEnd - sNewBox1
	call CopyBytes
	jp CloseSRAM

UpdateStackTop:
; sStackTop appears to be unused.
; It could have been used to debug stack overflow during saving.
	call FindStackTop
	ld a, BANK(sStackTop)
	call OpenSRAM
	ld a, [sStackTop + 0]
	ld e, a
	ld a, [sStackTop + 1]
	ld d, a
	or e
	jr z, .update
	ld a, e
	sub l
	ld a, d
	sbc h
	jr c, .done

.update
	ld a, l
	ld [sStackTop + 0], a
	ld a, h
	ld [sStackTop + 1], a

.done
	call CloseSRAM
	ret

FindStackTop:
; Find the furthest point that sp has traversed to.
; This is distinct from the current value of sp.
	ld hl, wStackBottom
.loop
	ld a, [hl]
	or a
	ret nz
	inc hl
	jr .loop

SavingDontTurnOffThePower:
	; Prevent joypad interrupts
	xor a
	ldh [hJoypadReleased], a
	ldh [hJoypadPressed], a
	ldh [hJoypadSum], a
	ldh [hJoypadDown], a
	; Save the text speed setting to the stack
	ld a, [wOptions]
	push af
	; Set the text speed to medium
	ld a, TEXT_DELAY_MED
	ld [wOptions], a
	; SAVING... DON'T TURN OFF THE POWER.
	ld hl, SavingDontTurnOffThePowerText
	call PrintText
	; Restore the text speed setting
	pop af
	ld [wOptions], a
	; Wait for 16 frames
	ld c, 16
	call DelayFrames
	ret

ErasePreviousSave:
	call EraseHallOfFame
	call EraseLinkBattleStats
	call EraseMysteryGift
	call SaveData
	call EraseBattleTowerStatus
	ld a, BANK(sStackTop)
	call OpenSRAM
	xor a
	ld [sStackTop + 0], a
	ld [sStackTop + 1], a
	call CloseSRAM
	ld a, $1
	ld [wSavedAtLeastOnce], a
	ret

EraseLinkBattleStats:
	ld a, BANK(sLinkBattleStats)
	call OpenSRAM
	ld hl, sLinkBattleStats
	ld bc, sLinkBattleStatsEnd - sLinkBattleStats
	xor a
	call ByteFill
	jp CloseSRAM

EraseMysteryGift:
	ld a, BANK(sBackupMysteryGiftItem)
	call OpenSRAM
	ld hl, sBackupMysteryGiftItem
	ld bc, sBackupMysteryGiftItemEnd - sBackupMysteryGiftItem
	xor a
	call ByteFill
	jp CloseSRAM

EraseHallOfFame:
	ld a, BANK(sHallOfFame)
	call OpenSRAM
	ld hl, sHallOfFame
	ld bc, sHallOfFameEnd - sHallOfFame
	xor a
	call ByteFill
	jp CloseSRAM

InitDefaultEZChatMsgs: ; unreferenced
	ld a, BANK(sEZChatMessages) ; MBC30 bank used by JP Crystal; inaccessible by MBC3
	call OpenSRAM
	ld hl, .Data
	ld de, sEZChatMessages
	ld bc, EASY_CHAT_MESSAGE_LENGTH * 4
	call CopyBytes
	jp CloseSRAM

.Data:
; introduction
	db $0d, EZCHAT_GREETINGS,    $00, EZCHAT_EXCLAMATIONS, $00, EZCHAT_POKEMON
	db $22, EZCHAT_GREETINGS,    $01, EZCHAT_EXCLAMATIONS, $00, EZCHAT_POKEMON
; begin battle
	db $03, EZCHAT_BATTLE,       $05, EZCHAT_CONDITIONS,   $03, EZCHAT_EXCLAMATIONS
	db $0e, EZCHAT_CONVERSATION, $03, EZCHAT_GREETINGS,    $00, EZCHAT_POKEMON
; win battle
	db $39, EZCHAT_FEELINGS,     $07, EZCHAT_BATTLE,       $00, EZCHAT_EXCLAMATIONS
	db $04, EZCHAT_FEELINGS,     $01, EZCHAT_EXCLAMATIONS, $00, EZCHAT_POKEMON
; lose battle
	db $0f, EZCHAT_EXCLAMATIONS, $14, EZCHAT_FEELINGS,     $05, EZCHAT_EXCLAMATIONS
	db $11, EZCHAT_TIME,         $0c, EZCHAT_CONVERSATION, $06, EZCHAT_BATTLE

EraseBattleTowerStatus:
	ld a, BANK(sBattleTowerChallengeState)
	call OpenSRAM
	xor a
	ld [sBattleTowerChallengeState], a
	jp CloseSRAM

SaveData:
	call _SaveData
	ret

Function14d6c: ; unreferenced
	ld a, BANK(s4_a60b) ; MBC30 bank used by JP Crystal; inaccessible by MBC3
	call OpenSRAM
	ld a, [s4_a60b] ; address of MBC30 bank
	ld b, $0
	and a
	jr z, .ok
	ld b, $2

.ok
	ld a, b
	ld [s4_a60b], a ; address of MBC30 bank
	call CloseSRAM
	ret

Function14d83: ; unreferenced
	ld a, BANK(s4_a60c) ; aka BANK(s4_a60d) ; MBC30 bank used by JP Crystal; inaccessible by MBC3
	call OpenSRAM
	xor a
	ld [s4_a60c], a ; address of MBC30 bank
	ld [s4_a60d], a ; address of MBC30 bank
	call CloseSRAM
	ret

DisableMobileStadium: ; unreferenced
	ld a, BANK(sMobileStadiumFlag)
	call OpenSRAM
	xor a
	ld [sMobileStadiumFlag], a
	call CloseSRAM
	ret

HallOfFame_InitSaveIfNeeded:
	ld a, [wSavedAtLeastOnce]
	and a
	ret nz
	call ErasePreviousSave
	ret

ValidateSave:
	ld a, BANK(sCheckValue1) ; aka BANK(sCheckValue2)
	call OpenSRAM
	ld a, SAVE_CHECK_VALUE_1
	ld [sCheckValue1], a
	ld a, SAVE_CHECK_VALUE_2
	ld [sCheckValue2], a
	jp CloseSRAM

SaveOptions:
	ld a, BANK(sOptions)
	call OpenSRAM
	ld hl, wOptions
	ld de, sOptions
	ld bc, wOptionsEnd - wOptions
	call CopyBytes
	ld a, [wOptions]
	and ~(1 << NO_TEXT_SCROLL)
	ld [sOptions], a
	jp CloseSRAM

SavePlayerData:
	ld a, BANK(sPlayerData)
	call OpenSRAM
	ld hl, wPlayerData
	ld de, sPlayerData
	ld bc, wPlayerDataEnd - wPlayerData
	call CopyBytes
	ld hl, wCurMapData
	ld de, sCurMapData
	ld bc, wCurMapDataEnd - wCurMapData
	call CopyBytes
	jp CloseSRAM

SavePokemonData:
	ld a, BANK(sPokemonData)
	call OpenSRAM
	ld hl, wPokemonData
	ld de, sPokemonData
	ld bc, wPokemonDataEnd - wPokemonData
	call CopyBytes
	call CloseSRAM
	ret

SaveChecksum:
	ld hl, sGameData
	ld bc, sGameDataEnd - sGameData
	ld a, BANK(sGameData)
	call OpenSRAM
	call Checksum
	ld a, e
	ld [sChecksum + 0], a
	ld a, d
	ld [sChecksum + 1], a
	call CloseSRAM
	ret

ValidateBackupSave:
	ld a, BANK(sBackupCheckValue1) ; aka BANK(sBackupCheckValue2)
	call OpenSRAM
	ld a, SAVE_CHECK_VALUE_1
	ld [sBackupCheckValue1], a
	ld a, SAVE_CHECK_VALUE_2
	ld [sBackupCheckValue2], a
	call CloseSRAM
	ret

SaveBackupOptions:
	ld a, BANK(sBackupOptions)
	call OpenSRAM
	ld hl, wOptions
	ld de, sBackupOptions
	ld bc, wOptionsEnd - wOptions
	call CopyBytes
	call CloseSRAM
	ret

SaveBackupPlayerData:
	ld a, BANK(sBackupPlayerData)
	call OpenSRAM
	ld hl, wPlayerData
	ld de, sBackupPlayerData
	ld bc, wPlayerDataEnd - wPlayerData
	call CopyBytes
	ld hl, wCurMapData
	ld de, sBackupCurMapData
	ld bc, wCurMapDataEnd - wCurMapData
	call CopyBytes
	call CloseSRAM
	ret

SaveBackupPokemonData:
	ld a, BANK(sBackupPokemonData)
	call OpenSRAM
	ld hl, wPokemonData
	ld de, sBackupPokemonData
	ld bc, wPokemonDataEnd - wPokemonData
	call CopyBytes
	call CloseSRAM
	ret

SaveBackupChecksum:
	ld hl, sBackupGameData
	ld bc, sBackupGameDataEnd - sBackupGameData
	ld a, BANK(sBackupGameData)
	call OpenSRAM
	call Checksum
	ld a, e
	ld [sBackupChecksum + 0], a
	ld a, d
	ld [sBackupChecksum + 1], a
	call CloseSRAM
	ret

WasMidSaveAborted:
; Returns z if the system was reset mid-saving.
	ld a, BANK(sWritingBackup)
	call OpenSRAM
	ld a, [sWritingBackup]
	dec a
	jp CloseSRAM

SetSavePhase:
; set current save phase: 1 (saving), 0 (not saving).
	push af
	ld a, BANK(sWritingBackup)
	call OpenSRAM
	pop af
	ld [sWritingBackup], a
	jp CloseSRAM

TryLoadSaveFile:
	call VerifyChecksum
	jr nz, .backup
	call LoadPlayerData
	call LoadPokemonData
	; If a mid-save was aborted but main save data is good, finish it.
	call WasMidSaveAborted
	call z, WriteBackupSave
	farcall RestorePartyMonMail
	farcall RestoreGSBallFlag
	farcall RestoreMysteryGift
	call LoadStorageSystem

	; Just in case
	call WriteBackupSave
	and a
	ret

.backup
	call VerifyBackupChecksum
	jr nz, .corrupt
	call LoadBackupPlayerData
	call LoadBackupPokemonData
	farcall RestorePartyMonMail
	farcall RestoreGSBallFlag
	farcall RestoreMysteryGift
	call LoadStorageSystem
	call SaveGameData
	and a
	ret

.corrupt
	ld a, [wOptions]
	push af
	set NO_TEXT_SCROLL, a
	ld [wOptions], a
	ld hl, SaveFileCorruptedText
	call PrintText
	pop af
	ld [wOptions], a
	scf
	ret

TryLoadSaveData:
	xor a ; FALSE
	ld [wSaveFileExists], a
	call CheckPrimarySaveFile
	ld a, [wSaveFileExists]
	and a
	jr z, .backup

	ld a, BANK(sPlayerData)
	call OpenSRAM
	ld hl, sPlayerData + wStartDay - wPlayerData
	ld de, wStartDay
	ld bc, 8
	call CopyBytes
	ld hl, sPlayerData + wStatusFlags - wPlayerData
	ld de, wStatusFlags
	ld a, [hl]
	ld [de], a
	call CloseSRAM
	ret

.backup
	call CheckBackupSaveFile
	ld a, [wSaveFileExists]
	and a
	jr z, .corrupt

	ld a, BANK(sBackupPlayerData)
	call OpenSRAM
	ld hl, sBackupPlayerData + wStartDay - wPlayerData
	ld de, wStartDay
	ld bc, 8
	call CopyBytes
	ld hl, sBackupPlayerData + wStatusFlags - wPlayerData
	ld de, wStatusFlags
	ld a, [hl]
	ld [de], a
	call CloseSRAM
	ret

.corrupt
	ld hl, DefaultOptions
	ld de, wOptions
	ld bc, wOptionsEnd - wOptions
	call CopyBytes
	call ClearClock
	ret

INCLUDE "data/default_options.asm"

CheckPrimarySaveFile:
	ld a, BANK(sCheckValue1) ; aka BANK(sCheckValue2)
	call OpenSRAM
	ld a, [sCheckValue1]
	cp SAVE_CHECK_VALUE_1
	jr nz, .nope
	ld a, [sCheckValue2]
	cp SAVE_CHECK_VALUE_2
	jr nz, .nope
	ld hl, sOptions
	ld de, wOptions
	ld bc, wOptionsEnd - wOptions
	call CopyBytes
	call CloseSRAM
	ld a, TRUE
	ld [wSaveFileExists], a

.nope
	call CloseSRAM
	ret

CheckBackupSaveFile:
	ld a, BANK(sBackupCheckValue1) ; aka BANK(sBackupCheckValue2)
	call OpenSRAM
	ld a, [sBackupCheckValue1]
	cp SAVE_CHECK_VALUE_1
	jr nz, .nope
	ld a, [sBackupCheckValue2]
	cp SAVE_CHECK_VALUE_2
	jr nz, .nope
	ld hl, sBackupOptions
	ld de, wOptions
	ld bc, wOptionsEnd - wOptions
	call CopyBytes
	ld a, $2
	ld [wSaveFileExists], a

.nope
	call CloseSRAM
	ret

LoadPlayerData:
	ld a, BANK(sPlayerData)
	call OpenSRAM
	ld hl, sPlayerData
	ld de, wPlayerData
	ld bc, wPlayerDataEnd - wPlayerData
	call CopyBytes
	ld hl, sCurMapData
	ld de, wCurMapData
	ld bc, wCurMapDataEnd - wCurMapData
	call CopyBytes
	call CloseSRAM
	ld a, BANK(sBattleTowerChallengeState)
	call OpenSRAM
	ld a, [sBattleTowerChallengeState]
	cp BATTLETOWER_RECEIVED_REWARD
	jr nz, .not_4
	ld a, BATTLETOWER_WON_CHALLENGE
	ld [sBattleTowerChallengeState], a
.not_4
	call CloseSRAM
	ret

LoadPokemonData:
	ld a, BANK(sPokemonData)
	call OpenSRAM
	ld hl, sPokemonData
	ld de, wPokemonData
	ld bc, wPokemonDataEnd - wPokemonData
	call CopyBytes
	call CloseSRAM
	ret

VerifyChecksum:
	ld hl, sGameData
	ld bc, sGameDataEnd - sGameData
	ld a, BANK(sGameData)
	call OpenSRAM
	call Checksum
	ld a, [sChecksum + 0]
	cp e
	jr nz, .fail
	ld a, [sChecksum + 1]
	cp d
.fail
	push af
	call CloseSRAM
	pop af
	ret

LoadBackupPlayerData:
	ld a, BANK(sBackupPlayerData)
	call OpenSRAM
	ld hl, sBackupPlayerData
	ld de, wPlayerData
	ld bc, wPlayerDataEnd - wPlayerData
	call CopyBytes
	ld hl, sBackupCurMapData
	ld de, wCurMapData
	ld bc, wCurMapDataEnd - wCurMapData
	call CopyBytes
	call CloseSRAM
	ret

LoadBackupPokemonData:
	ld a, BANK(sBackupPokemonData)
	call OpenSRAM
	ld hl, sBackupPokemonData
	ld de, wPokemonData
	ld bc, wPokemonDataEnd - wPokemonData
	call CopyBytes
	call CloseSRAM
	ret

VerifyBackupChecksum:
	ld hl, sBackupGameData
	ld bc, sBackupGameDataEnd - sBackupGameData
	ld a, BANK(sBackupGameData)
	call OpenSRAM
	call Checksum
	ld a, [sBackupChecksum + 0]
	cp e
	jr nz, .fail
	ld a, [sBackupChecksum + 1]
	cp d
.fail
	push af
	call CloseSRAM
	pop af
	ret

_SaveData:
	; This is called within two scenarios:
	;   a) ErasePreviousSave (the process of erasing the save from a previous game file)
	;   b) unused mobile functionality
	; It is not part of a regular save.

	ld a, BANK(sCrystalData)
	call OpenSRAM
	ld hl, wCrystalData
	ld de, sCrystalData
	ld bc, wCrystalDataEnd - wCrystalData
	call CopyBytes

	; This block originally had some mobile functionality, but since we're still in
	; BANK(sCrystalData), it instead overwrites the sixteen wEventFlags starting at 1:s4_a60e with
	; garbage from wd479. This isn't an issue, since ErasePreviousSave is followed by a regular
	; save that unwrites the garbage.

	ld hl, wd479
	ld a, [hli]
	ld [s4_a60e + 0], a
	ld a, [hli]
	ld [s4_a60e + 1], a

	jp CloseSRAM

_LoadData:
	ld a, BANK(sCrystalData)
	call OpenSRAM
	ld hl, sCrystalData
	ld de, wCrystalData
	ld bc, wCrystalDataEnd - wCrystalData
	call CopyBytes

	; This block originally had some mobile functionality to mirror _SaveData above, but instead it
	; (harmlessly) writes the aforementioned wEventFlags to the unused wd479.

	ld hl, wd479
	ld a, [s4_a60e + 0]
	ld [hli], a
	ld a, [s4_a60e + 1]
	ld [hli], a

	jp CloseSRAM

Checksum:
	ld de, 0
.loop
	ld a, [hli]
	add e
	ld e, a
	ld a, 0
	adc d
	ld d, a
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret

WouldYouLikeToSaveTheGameText:
	text_far _WouldYouLikeToSaveTheGameText
	text_end

SavedTheGameText:
	text_far _SavedTheGameText
	text_end

AnotherSaveFileText:
	text_far _AnotherSaveFileText
	text_end

SaveFileCorruptedText:
	text_far _SaveFileCorruptedText
	text_end
