; Squirrel Domino
; Implementation of expired U.S. Patent 5265888
;
; Copyright 2019, 2024 NovaSquirrel
; 
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
; 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
; 
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;

NUM_PLAYERS = 2
SCORE_LENGTH = 6

.segment "ZEROPAGE"
  random0:  .res NUM_PLAYERS
  random1:  .res NUM_PLAYERS
  random2:  .res NUM_PLAYERS
  random3:  .res NUM_PLAYERS

  keydown:  .res NUM_PLAYERS
  keylast:  .res NUM_PLAYERS
  keynew:   .res NUM_PLAYERS
  key_new_or_repeat: .res NUM_PLAYERS
  retraces: .res 1
  KeyRepeatTimer: .res NUM_PLAYERS

  TitleCursorY: .res 1
  PlayerReady: .res NUM_PLAYERS
PuzzleZeroStart:
  PuzzleState:    .res NUM_PLAYERS ; State each playfield is in
  ; For the experimental swap mode
  PuzzleSwapX:    .res NUM_PLAYERS
  PuzzleSwapY:    .res NUM_PLAYERS
  PuzzleSwapMode: .res NUM_PLAYERS ; If players are in swap mode or not
  PuzzleVirusesClearedThisMove: .res NUM_PLAYERS

  ; Send garbage
  PuzzleMatchesMade: .res NUM_PLAYERS   ; Matches made between dropping each piece
  PuzzleMatchColor:  .res NUM_PLAYERS*4 ; First player's four colors, then second player's

  ; Receive garbage
  PuzzleGarbageCount: .res NUM_PLAYERS
  PuzzleGarbageColor: .res NUM_PLAYERS*4
  LockoutSoftDrop:    .res NUM_PLAYERS ; Don't allow soft drop until you press down again
PuzzleZeroEnd:

  PuzzleX:          .res NUM_PLAYERS
  PuzzleY:          .res NUM_PLAYERS
  PuzzleFallTimer:  .res NUM_PLAYERS ; Time until the piece falls down one row
  PuzzleDir:        .res NUM_PLAYERS ; Direction
  PuzzleColor1:     .res NUM_PLAYERS
  PuzzleColor2:     .res NUM_PLAYERS
  PuzzleNextColor1: .res NUM_PLAYERS
  PuzzleNextColor2: .res NUM_PLAYERS

  ; Low, medium or high
  PuzzleSpeed:        .res NUM_PLAYERS ; ranges 0-2. pills
  PuzzleGravitySpeed: .res NUM_PLAYERS ; ranges 0-2, gravity

  VirusLevel:    .res NUM_PLAYERS ; Number of viruses to clear, in this version
  PuzzleRedraw:  .res NUM_PLAYERS ; Redraw entire grid

  PuzzleVersus:  .res 1    ; If negative, versus mode
  PuzzleGimmick: .res 1    ; Gimmick selected
  PuzzlePieceTheme: .res 1 ; Theme picked
  PuzzlePieceColor: .res 1
  PuzzleBGTheme: .res 1

  PuzzlePlayfieldBase: .res 1 ; 0 or 128 for player 1 or 2
  PuzzleTileBase:      .res 1 ; $80, $a0, $c0, or $e0

  PuzzleXSpriteOffset: .res NUM_PLAYERS ; Distance to add to X for player 1 and 2's pills and next piece
  PPU_UpdateLo:        .res NUM_PLAYERS ; Low byte of a PPU update for pill placement
  PPU_UpdateHi:        .res NUM_PLAYERS ; High update of a PPU update for pill placement

  PuzzleMusicChoice:   .res 1      ; Which music is picked

; Randomizer state:
  PUZZLE_OUTCOMES = 9
  PUZZLE_RANDBUF_SIZE = PUZZLE_OUTCOMES * 3
  PUZZLE_PLAYERS = 2

  PuzzleRandBuf: .res PUZZLE_PLAYERS * PUZZLE_RANDBUF_SIZE
  PuzzleRandPos: .res PUZZLE_PLAYERS

  ; Stuff copied from Nova the Squirrel 1
  MaxNumTileUpdates  = 4
  TileUpdateA1:    .res MaxNumTileUpdates ; \ address
  TileUpdateA2:    .res MaxNumTileUpdates ; /
  TileUpdateT:     .res MaxNumTileUpdates ; new byte
  TempVal:     .res 4
  TempX:       .res 1 ; for saving the X register
  TempY:       .res 1 ; for saving the Y register
  OamPtr:      .res 1
  PlayerDir:   .res 1
  TouchTemp:   .res 10

.segment "BSS"
  PlayerScore:     .res SCORE_LENGTH+1 ; 1 byte per digit. Only for player 1. Ones digit first.
  ; There's an extra byte on the end to simplify some code
  PlayerBestScore: .res SCORE_LENGTH

  PuzzleMap = $700 ; 128 bytes, 8*16
