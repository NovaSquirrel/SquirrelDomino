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

.proc PuzzlePlaySFX
  stx TempX
  sty TempY

  ; Only play if SFX enabled
  ; (all options except 0 enable it)
  sta TouchTemp+9
  lda PuzzleMusicChoice
  beq :+
    lda TouchTemp+9
    ldx #FT_SFX_CH0
    jsr FamiToneSfxPlay
  :

  ldy TempY
  ldx TempX
  rts
.endproc

; -------------------------------------

.proc InitPuzzleGame
  ; Clear the stuff that should be zero'd every new game
  ldy #PuzzleZeroEnd-PuzzleZeroStart-1
  lda #0
: sta PuzzleZeroStart,y
  dey
  bpl :-

  jsr PuzzleRandomInit

  jsr WaitVblank
  lda #0
  sta PPUMASK

  ; Set palettes
  ldx #$3f
  stx PPUADDR
  lda #$0d
  sta PPUADDR
  jsr WritePieceColors
  stx PPUADDR
  lda #$1d
  sta PPUADDR
  jsr WritePieceColors

  ; Change background color
  stx PPUADDR
  lda #0
  sta PPUADDR

  ldy PuzzleBGTheme
  ; First palette
  lda BackgroundBGColor,y
  sta PPUDATA
  lda BackgroundColor11,y
  sta PPUDATA
  lda BackgroundColor12,y
  sta PPUDATA
  lda BackgroundColor13,y
  sta PPUDATA

  ; Second palette
  stx PPUADDR
  lda #5
  sta PPUADDR
  lda BackgroundColor21,y
  sta PPUDATA
  lda BackgroundColor22,y
  sta PPUDATA
  lda BackgroundColor23,y
  sta PPUDATA

  ; Third palette
  stx PPUADDR
  lda #9
  sta PPUADDR
  lda BackgroundColor31,y
  sta PPUDATA
  lda BackgroundColor32,y
  sta PPUDATA
  lda BackgroundColor33,y
  sta PPUDATA

  ldy PuzzlePieceTheme
  lda PieceThemeTileBases,y
  sta PuzzleTileBase

  ; Erase first tile
  ; (so that 0 in the playfield is actually empty space)
  lda #$00
  sta PPUADDR
  sta PPUADDR
  jsr WritePPURepeated16

  jsr PuzzleAddBackground

  lda PuzzleVersus
  jne DrawVersusPlayfields
  .scope

  lda #0
  sta PuzzleXSpriteOffset
  lda #<($2000 + 32*6 + 12)
  sta PPU_UpdateLo
  lda #>($2000 + 32*6 + 12)
  sta PPU_UpdateHi

  ; Set attributes
  lda #$23
  sta PPUADDR
  lda #$cb
  sta PPUADDR
  lda #%11110000
  sta PPUDATA
  sta PPUDATA
  ldy #3
: jsr SkipAheadSix
  lda #%11111111
  sta PPUDATA
  sta PPUDATA
  dey
  bne :-
  jsr SkipAheadSix
  lda #%00001111
  sta PPUDATA
  sta PPUDATA

  ; "Score" text
  lda #$23
  sta PPUADDR
  lda #$0C
  sta PPUADDR
  ldx #$4A
  stx PPUDATA
  inx
  stx PPUDATA
  inx
  stx PPUDATA
  inx
  stx PPUDATA

  .if 0
  ; "Best" text
  lda #$23
  sta PPUADDR
  lda #$4C
  sta PPUADDR
  ldx #$06
  stx PPUDATA
  inx
  stx PPUDATA
  inx
  stx PPUDATA
  inx
  stx PPUDATA
  .endif

  ; Set attribute for score
  lda PuzzleBGTheme
  cmp #5
  beq :+
  cmp #1
  bne :++
:
    lda #$23
    sta PPUADDR
    lda #$f3
    sta PPUADDR
    lda #%00001111 ;#%11111111
    sta PPUDATA
    sta PPUDATA
  :

  ; Make the playfield border
  ; Top
  PositionXY 0, 11, 5
  lda #$98
  sta PPUDATA
  lda #$99
  ldx #8
  jsr WritePPURepeated
  lda #$9a
  sta PPUDATA
  ; Bottom
  PositionXY 0, 11, 22
  lda #$9d
  sta PPUDATA
  lda #$9e
  ldx #8
  jsr WritePPURepeated
  lda #$9f
  sta PPUDATA
  ; Make sides
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_DOWN
  sta PPUCTRL
  PositionXY 0, 11, 6
  lda #$9b
  jsr WritePPURepeated16
  PositionXY 0, 20, 6
  lda #$9c
  jsr WritePPURepeated16
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_RIGHT
  sta PPUCTRL

  .endscope
  jmp DrewSoloPlayfield
DrawVersusPlayfields:
  .scope
  ; Offset things away from the center and into the two playfields
  lda #<-64
  sta PuzzleXSpriteOffset+0
  lda #64
  sta PuzzleXSpriteOffset+1

  lda #<($2000 + 32*6 + 4)
  sta PPU_UpdateLo+0
  lda #>($2000 + 32*6 + 4)
  sta PPU_UpdateHi+0
  lda #<($2000 + 32*6 + 20)
  sta PPU_UpdateLo+1
  lda #>($2000 + 32*6 + 20)
  sta PPU_UpdateHi+1

  ; Set attributes
  lda #$23
  sta PPUADDR
  lda #$c9
  sta PPUADDR
  ldx #0

  lda #%11110000
  sta PPUDATA
  sta PPUDATA
  jsr stx_stx_sta_sta
  lda #%11111111
  ldy #6
: jsr stx_stx_sta_sta
  dey
  bne :-
  lda #%00001111
  jsr stx_stx_sta_sta
  jsr stx_stx_sta_sta

  ; Make the playfield border
  ; Top
  PositionXY 0, 3, 5
  lda #$98
  sta PPUDATA
  lda #$99
  ldx #8
  jsr WritePPURepeated
  lda #$9a
  sta PPUDATA
  ; Bottom
  PositionXY 0, 3, 22
  lda #$9d
  sta PPUDATA
  lda #$9e
  ldx #8
  jsr WritePPURepeated
  lda #$9f
  sta PPUDATA
  ; Make sides
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_DOWN
  sta PPUCTRL
  PositionXY 0, 3, 6
  lda #$9b
  jsr WritePPURepeated16
  PositionXY 0, 12, 6
  lda #$9c
  jsr WritePPURepeated16
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_RIGHT
  sta PPUCTRL

  ; Player 2's borders
  PositionXY 0, 19, 5
  lda #$98
  sta PPUDATA
  lda #$99
  ldx #8
  jsr WritePPURepeated
  lda #$9a
  sta PPUDATA
  ; Bottom
  PositionXY 0, 19, 22
  lda #$9d
  sta PPUDATA
  lda #$9e
  ldx #8
  jsr WritePPURepeated
  lda #$9f
  sta PPUDATA
  ; Make sides
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_DOWN
  sta PPUCTRL
  PositionXY 0, 19, 6
  lda #$9b
  jsr WritePPURepeated16
  PositionXY 0, 28, 6
  lda #$9c
  jsr WritePPURepeated16
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_RIGHT
  sta PPUCTRL
  .endscope
DrewSoloPlayfield:

  jsr PuzzleMusicInit

  lda PuzzleMusicChoice
  and #2
  beq :+
    lda PuzzleMusicChoice
    and #1
    jsr FamiToneMusicPlay
  :

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

  jsr ClearOAM

  ; The game loop!
Loop:
  jsr FamiToneUpdate

  jsr WaitVblank
  lda #BG_ON|OBJ_ON
  sta PPUMASK
  lda #2
  sta OAM_DMA

  ; probably should clear this out before it's used?
  .repeat 4, I ; reuse this stuff from Nova the Squirrel
    lda TileUpdateA1+I
    beq :+
      sta PPUADDR
      lda TileUpdateA2+I
      sta PPUADDR
      lda TileUpdateT+I
      sta PPUDATA
      lda #0
      sta TileUpdateA1+I
    :
  .endrep

  ; Redraw the whole playfield if necessary
  lda PuzzleRedraw
  beq :+
    jsr PuzzleDrawSolo
    lda #0
    sta PuzzleRedraw
    jmp DontDrawPlayer2 ; Skip player 2 to avoid overflowing vblank
  :
  lda PuzzleRedraw+1
  beq :+
    jsr PuzzleDrawVersus2
    lda #0
    sta PuzzleRedraw+1
  :

  lda PuzzleVersus
  beq :+
    jmp DontDrawPlayer2
  :
    ; Current score
    lda #$23
    sta PPUADDR
    lda #$2c
    sta PPUADDR
    .repeat 6, I
      lda PlayerScore+(SCORE_LENGTH-I-1)
      ora #$40
      sta PPUDATA
    .endrep
    lda #$40
    sta PPUDATA
    sta PPUDATA

    .if 0
    ; Top score
    lda #$23
    sta PPUADDR
    lda #$6c
    sta PPUADDR
    .repeat 6, I
      lda PlayerBestScore+(SCORE_LENGTH-I-1)
      ora #$40
      sta PPUDATA
    .endrep
    lda #$40
    sta PPUDATA
    sta PPUDATA
    .endif
  DontDrawPlayer2:

  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_1000 | OBJ_1000 | VRAM_RIGHT
  sta PPUCTRL
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

  ; -----------------------------------

  jsr PuzzleReadJoy
  ldx #0
  jsr KeyRepeat
  inx
  jsr KeyRepeat
  jsr ClearOAM

  ldx #0
  stx PuzzlePlayfieldBase
  jsr PuzzleDoPlayer
  lda PuzzleVersus
  beq :+ ; set to 128 when versus mode is on
    sta PuzzlePlayfieldBase
    ldx #1
    jsr PuzzleDoPlayer
  :

  ; Pausing
  lda keynew
  and #KEY_START
  beq NoPause
    ; Don't allow pausing if someone is winning or losing
    lda PuzzleState+0
    cmp #PuzzleStates::VICTORY
    beq NoPause
    cmp #PuzzleStates::FAILURE
    beq NoPause
    lda PuzzleState+1
    cmp #PuzzleStates::VICTORY
    beq NoPause
    cmp #PuzzleStates::FAILURE
    beq NoPause

    lda #1
    jsr FamiToneMusicPause
    jsr FamiToneUpdate

    lda keydown
    and #KEY_SELECT
    jne PuzzleGameMenu::Reshow
    lda #VBLANK_NMI | NT_2400 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_RIGHT
    sta PPUCTRL
    lda #BG_ON
    sta PPUMASK

    ; Debounce
    ldy #15
    sty TempY
  : jsr WaitVblank
    jsr FamiToneUpdate
    dec TempY
    bne :-

    ; Wait
  : jsr WaitVblank
    jsr FamiToneUpdate
    jsr PuzzleReadJoy
    lda keynew
    and #KEY_START
    beq :-

    ; Debounce
    ldy #15
    sty TempY
  : jsr WaitVblank
    jsr FamiToneUpdate
    dec TempY
    bne :-


    lda #0
    jsr FamiToneMusicPause

    lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_1000 | OBJ_1000 | VRAM_RIGHT
    sta PPUCTRL
    lda #BG_ON|OBJ_ON
    sta PPUMASK
  NoPause:

  jmp Loop

stx_stx_sta_sta:
  stx PPUDATA
  stx PPUDATA
  sta PPUDATA
  sta PPUDATA
  rts

SkipAheadSix:
  bit PPUDATA
  bit PPUDATA
  bit PPUDATA
  bit PPUDATA
  bit PPUDATA
  bit PPUDATA
  rts

::WritePieceColors:
  ldy PuzzlePieceColor
  lda PieceColor1,y
  sta PPUDATA
  lda PieceColor2,y
  sta PPUDATA
  lda PieceColor3,y
  sta PPUDATA
  rts
PieceColor1:
  .byt $16, $16, $25, $15
PieceColor2:
  .byt $2a, $28, $37, $29
PieceColor3:
  .byt $22, $13, $2c, $2c

::PieceThemeTileBases:
  .byt $80, $a0, $c0
.endproc

.proc PuzzleDrawSolo ; Unrolled loop to update player 1 when in the middle
  lda PuzzleVersus
  jne PuzzleDrawVersus1
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_DOWN
  sta PPUCTRL
  .repeat 8, I
    lda #>($2000 + (6*32)+(12+I))
    sta PPUADDR
    lda #<($2000 + (6*32)+(12+I))
    sta PPUADDR
    ldx #16*I
    jsr PuzzleDrawColumn
  .endrep
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_RIGHT
  sta PPUCTRL
  rts
.endproc

.proc PuzzleDrawColumn
  .repeat 16, J
    lda PuzzleMap+J,x
    sta PPUDATA
  .endrep
  rts
.endproc

.proc PuzzleDrawVersus1 ; Unrolled loop to update player 1 when on the left
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_DOWN
  sta PPUCTRL
  .repeat 8, I
    lda #>($2000 + (6*32)+(4+I))
    sta PPUADDR
    lda #<($2000 + (6*32)+(4+I))
    sta PPUADDR
    ldx #16*I
    jsr PuzzleDrawColumn
  .endrep
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_RIGHT
  sta PPUCTRL
  rts
.endproc

.proc PuzzleDrawVersus2 ; Unrolled loop to update player 2, who's on the right
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_DOWN
  sta PPUCTRL
  .repeat 8, I
    lda #>($2000 + (6*32)+(20+I))
    sta PPUADDR
    lda #<($2000 + (6*32)+(20+I))
    sta PPUADDR
    ldx #16*I+128
    jsr PuzzleDrawColumn
  .endrep
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_RIGHT
  sta PPUCTRL
  rts
.endproc

; Display a victory (or failure) message and then exit to menu
PuzzleFailure:
.proc PuzzleVictory
  lda PuzzleFallTimer,x
  jeq NoDelayLeft
    dec PuzzleFallTimer,x

    beq :+
JumpToTimerNotDone:
      jmp TimerNotDone
    :
    lda PuzzleVersus
    bmi JumpToTimerNotDone
      ; Just clear the screen
      ldy #127
    ClearScreenLoop:
      tya
      and #15
      beq :+
        lda #0
        sta PuzzleMap,y
      :
      dey
      bne ClearScreenLoop

      ; Timer just turned to zero, and not multiplayer, so display "Continue?" menu
      ; "Continue?"
      ldy #$53
      sty PuzzleMap+PUZZLE_HEIGHT*0+7
      iny
      sty PuzzleMap+PUZZLE_HEIGHT*1+7
      iny
      sty PuzzleMap+PUZZLE_HEIGHT*2+7
      iny
      sty PuzzleMap+PUZZLE_HEIGHT*3+7
      iny
      sty PuzzleMap+PUZZLE_HEIGHT*4+7
      iny
      sty PuzzleMap+PUZZLE_HEIGHT*5+7
      iny
      sty PuzzleMap+PUZZLE_HEIGHT*6+7

      ; "Yes"
      ldy #$5a
      sty PuzzleMap+PUZZLE_HEIGHT*1+8
      iny
      sty PuzzleMap+PUZZLE_HEIGHT*2+8
      iny
      sty PuzzleMap+PUZZLE_HEIGHT*3+8

      ; "No"
      ldy #$5d
      sty PuzzleMap+PUZZLE_HEIGHT*1+9
      iny
      sty PuzzleMap+PUZZLE_HEIGHT*2+9

      lda #0
      sta PuzzleY

      lda PuzzleGimmick
      bne UsingGimmick
      ldx #0
      ldy #SCORE_LENGTH-1
    : lda PlayerBestScore,y
      ora #$40
      sta PuzzleMap+PUZZLE_HEIGHT-1,x
      txa
      add #PUZZLE_HEIGHT
      tax
      dey
      bpl :-
      lda #$40
      sta PuzzleMap+PUZZLE_HEIGHT*7-1
      sta PuzzleMap+PUZZLE_HEIGHT*8-1

      ; "Best"
      ldy #6
      sty PuzzleMap+PUZZLE_HEIGHT*1-2
      iny
      sty PuzzleMap+PUZZLE_HEIGHT*2-2
      iny
      sty PuzzleMap+PUZZLE_HEIGHT*3-2
      iny
      sty PuzzleMap+PUZZLE_HEIGHT*4-2
    UsingGimmick:

      inc PuzzleRedraw
    TimerNotDone:
    rts
  NoDelayLeft:

  ; If it's multiplayer, just go back to the menu. If it's single player, operate the menu?
  lda PuzzleVersus
  bpl :+
ExitToMenu:
  pla
  pla
  jmp PuzzleGameMenu::Reshow
:

  lda keynew
  and #KEY_UP|KEY_DOWN
  beq :+
    lda PuzzleY
    eor #1
    sta PuzzleY
  :

  lda PuzzleY
  asl
  asl
  asl
  adc #14*8-1
  sta OAM_YPOS+8
  lda #12*8
  sta OAM_XPOS+8
  lda #1
  sta OAM_TILE+8
  lda #0
  sta OAM_ATTR+8

  lda keynew
  and #KEY_A|KEY_START
  beq NoA
    lda PuzzleY
    bne ExitToMenu

    lda PuzzleState
    cmp #PuzzleStates::VICTORY
    bne NotVictory
    ; Max out at 80
    lda VirusLevel
    add #4
    cmp #80
    bcc :+
      lda #80
    :
    sta VirusLevel+0
    bne WasVictory
    NotVictory:

    ; Reset the score when you retry after failing
    lda #0
    .repeat ::SCORE_LENGTH, I
    sta PlayerScore+I
    .endrep

    WasVictory:
    pla
    pla
    jmp InitPuzzleGame
  NoA:
  rts
.endproc

; Y = index of the other player
.proc PuzzleOtherPlayer
  txa
  eor #1
  tay
  rts
.endproc

.proc PuzzleMusicInit
  lda #1 ; NSTC
  ldx #<novapuzzle_music_data
  ldy #>novapuzzle_music_data
  jsr FamiToneInit

  ldx #<sounds
  ldy #>sounds
  jmp FamiToneSfxInit
.endproc

.proc CheckAgainstHighScore
  lda PuzzleGimmick
  ora PuzzleVersus
  bne Exit

  ldx #SCORE_LENGTH-1
Loop:
  lda PlayerBestScore,x
  cmp PlayerScore,x
  bcc NewHighScore
  beq KeepGoing
  bcs Exit
KeepGoing:
  dex
  bpl Loop
  rts

NewHighScore:
  ldx #SCORE_LENGTH-1
: lda PlayerScore,x
  sta PlayerBestScore,x
  dex
  bpl :-
Exit:
  rts
.endproc
