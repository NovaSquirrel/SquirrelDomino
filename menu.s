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

.proc PuzzleGameMenu
  CursorY = TempVal ; array of 2

  jsr ReseedRandomizer

  lda #2
  sta PuzzleMusicChoice
  lda #4 ; squirrel, light
  sta PuzzleTheme

  ; Clear RAM
  ldx #0
  tax
: sta $700,x
  sta PuzzleMap,x
  inx
  bne :-

  lda #4
  sta VirusLevel+0
  sta VirusLevel+1
  lda #1
  sta PuzzleSpeed+0
  sta PuzzleSpeed+1
  sta PuzzleGravitySpeed+0
  sta PuzzleGravitySpeed+1

Reshow:
  jsr PuzzleMusicInit

  lda PuzzleMusicChoice
  bne :+
    lda #0
    jsr FamiToneMusicPlay
  :

  ; Clear the stuff that should be zero'd every new game
  ldy #PuzzleZeroEnd-PuzzleZeroStart-1
  lda #0
: sta PuzzleZeroStart,y
  dey
  bpl :-

  ; Turn off screen and draw the menu
  jsr WaitVblank
  ldx #0
  stx PPUMASK

  ; Also make sure background is white
  lda #$3f
  sta PPUADDR
  stx PPUADDR ; X is zero still from above
  lda #$30
  sta PPUDATA


  lda #' '
  jsr ClearNameCustom
  jsr ClearOAM


  ; Menu border
  ; Top
  PositionXY 0, 4, 6
  lda #$98
  sta PPUDATA
  lda #$99
  ldx #21
  jsr WritePPURepeated
  lda #$9a
  sta PPUDATA
  ; Bottom
  PositionXY 0, 4, 20
  lda #$9d
  sta PPUDATA
  lda #$9e
  ldx #21
  jsr WritePPURepeated
  lda #$9f
  sta PPUDATA

  ; Make sides
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_DOWN
  sta PPUCTRL
  PositionXY 0, 4, 7
  lda #$9b
  ldx #13
  jsr WritePPURepeated
  PositionXY 0, 26, 7
  lda #$9c
  ldx #13
  jsr WritePPURepeated
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_RIGHT
  sta PPUCTRL


  ; Draw the menu options
;  PositionXY 0, 9, 4
;  jsr PutStringImmediate
;  .byt "- Capsules -",0
  PositionXY 0, 6, 4
  jsr PutStringImmediate
  .byt "- Squirrel Domino -",0

  ; -----------------------------------

  PositionXY 0, 6, 7
  jsr PutStringImmediate
  .byt " Mode: Solo  Versus",0

  PositionXY 0, 6, 9
  jsr PutStringImmediate
  .byt "Style: Classic",0

  PositionXY 0, 6, 11
  jsr PutStringImmediate
  .byt "Count: 1P:04  2P:04",0

  PositionXY 0, 6, 13
  jsr PutStringImmediate
  .byt "Speed: 1P:Md  2P:Md",0

  PositionXY 0, 6, 15
  jsr PutStringImmediate
  .byt " Fall: 1P:Md  2P:Md",0

  PositionXY 0, 6, 17
  jsr PutStringImmediate
  .byt "Theme: Minimal",0

  PositionXY 0, 6, 19
  jsr PutStringImmediate
  .byt "Sound: ",0

  ; -----------------------------------

  PositionXY 0, 3, 22
  jsr PutStringImmediate
  .byt "Guide ",$82,$93," to make lines of",0
;  .byt "Guide ",$aa,$ab," to make lines of",0

  PositionXY 0, 3, 23
  jsr PutStringImmediate
  .byt "4 or more. Clear out all ",$88,0

  PositionXY 0, 3, 24
  jsr PutStringImmediate
  .byt "to win!",0

  PositionXY 0, 5, 26
  jsr PutStringImmediate
  .byt "+: Move    A/B: Rotate",0

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  sta CursorY
  sta CursorY+1

Loop:
  jsr WaitVblank
  lda #BG_ON|OBJ_ON
  sta PPUMASK
  lda #2
  sta OAM_DMA

  ; Print the counts and speeds chosen
  PositionXY 0, 16, 11
  ldy VirusLevel+0
  jsr PutDecimal
  PositionXY 0, 23, 11
  ldy VirusLevel+1
  jsr PutDecimal

  ; Draw speed names
  PositionXY 0, 16, 13
  lda PuzzleSpeed+0
  jsr PutSpeedName
  PositionXY 0, 23, 13
  lda PuzzleSpeed+1
  jsr PutSpeedName

  ; Draw fall speed names
  PositionXY 0, 16, 15
  lda PuzzleGravitySpeed+0
  jsr PutSpeedName
  PositionXY 0, 23, 15
  lda PuzzleGravitySpeed+1
  jsr PutSpeedName

  ; Print style/gimmick name
  ; always 8 characters
  PositionXY 0, 13, 9
  lda PuzzleGimmick
  asl
  asl
  asl
  tax
  ldy #8
: lda PuzzleGimmickNames,x
  sta PPUDATA
  inx
  dey
  bne :-

  ; Print theme name
  ; always 8 characters
  PositionXY 0, 13, 17
  lda PuzzleTheme
  lsr
  asl
  asl
  asl
  tax
  ldy #8
: lda PuzzleThemeNames,x
  sta PPUDATA
  inx
  dey
  bne :-

  ; Draw light or dark
  ldy #$91 ; light
  lda PuzzleTheme
  lsr
  bcc :+
    ldy #$81 ; dark
  :
  sty PPUDATA

  ; Music names
  PositionXY 0, 13, 19
  lda PuzzleMusicChoice
  asl
  asl
  adc PuzzleMusicChoice ; Carry always clear
  tax
  ldy #5
: lda PuzzleMusicNames,x
  sta PPUDATA
  inx
  dey
  bne :-

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

  jsr PuzzleReadJoy
  ldx #0
  jsr KeyRepeat
  jsr RandomByte ; Step player 1's randomizer forward. Player 2's will just be a copy of player 1's
  inx
  jsr KeyRepeat

  jsr ClearOAM
  ldx #0
  jsr RunMenu
  inx
  jsr RunMenu

  ; Allow starting the game or returning to the menu
  lda keynew
  and #KEY_START
  jne InitPuzzleGame

  lda keynew
  and #KEY_B
  jne Reset

  ; Draw the next piece
  ldy OamPtr

  lda #5*8
  sta OAM_XPOS+0,y
  lda #25*8
  sta OAM_XPOS+4,y

  lda CursorY+0
  jsr ShiftCursorY
  sta OAM_YPOS+0,y
  lda CursorY+1
  jsr ShiftCursorY
  sta OAM_YPOS+4,y

  ; Draw the two cursors
  lda #$41
  sta OAM_TILE+0,y
  lda #$42
  sta OAM_TILE+4,y

  lda #OAM_COLOR_0
  sta OAM_ATTR+0,y
  sta OAM_ATTR+4,y

  ; Draw the solo/versus mode select
  lda #$51
  sta OAM_TILE+8,y
  lda #OAM_COLOR_1
  sta OAM_ATTR+8,y
  lda #7*8-1
  sta OAM_YPOS+8,y
  lda #12*8
  bit PuzzleVersus
  bpl :+
    lda #18*8
  :
  sta OAM_XPOS+8,y

  tya
  add #12
  sta OamPtr

  jmp Loop

ShiftCursorY:
  asl
  asl
  asl
  asl
  add #7*8-1
  rts

RunMenu:
  lda key_new_or_repeat,x
  and #KEY_UP
  beq :+
    dec CursorY,x
    bpl :+
      lda #6
      sta CursorY,x
  :

  lda key_new_or_repeat,x
  and #KEY_DOWN
  beq :+
    inc CursorY,x
    lda CursorY,x
    cmp #7
    bne :+
      lda #0
      sta CursorY,x
  :

  lda key_new_or_repeat,x
  and #KEY_LEFT
  beq @NotLeft
    ldy CursorY,x
    bne :+
      ; Solo/Versus
      lda PuzzleVersus
      eor #128
      sta PuzzleVersus
      jmp @NotLeft
    :
    dey
    bne @NotStyleL
      ; Style
      dec PuzzleGimmick
      bpl :+
        lda #PuzzleGimmicks::GIMMICK_COUNT-1
         sta PuzzleGimmick
      :
      jmp @NotLeft
    @NotStyleL:
    dey
    bne @NotLevelL
      dec VirusLevel,x
      bne :+
        lda #80
        sta VirusLevel,x
      :
      ; Level
      jmp @NotLeft
    @NotLevelL:
    dey
    bne @NotSpeedL
      ; Speed
      dec PuzzleSpeed,x
      bpl :+
        lda #2
        sta PuzzleSpeed,x
      :
      jmp @NotLeft
    @NotSpeedL:

    dey
    bne @NotGravityL
      ; Gravity
      dec PuzzleGravitySpeed,x
      bpl :+
        lda #2
        sta PuzzleGravitySpeed,x
      :
      jmp @NotLeft
    @NotGravityL:

    dey
    bne @NotThemeL
      dec PuzzleTheme
      bpl :+
        lda #5
        sta PuzzleTheme
      :
      jmp @NotLeft
    @NotThemeL:

    dec PuzzleMusicChoice
    lda PuzzleMusicChoice
    and #3
    sta PuzzleMusicChoice
  @NotLeft:

  lda key_new_or_repeat,x
  and #KEY_RIGHT
  jeq @NotRight
    ldy CursorY,x
    bne :+
      ; Solo/Versus
      lda PuzzleVersus
      eor #128
      sta PuzzleVersus
      jmp @NotRight
    :
    dey
    bne @NotStyleR
      ; Style
      inc PuzzleGimmick
      lda PuzzleGimmick
      cmp #PuzzleGimmicks::GIMMICK_COUNT
      bne :+
         lda #0
         sta PuzzleGimmick
      :
      jmp @NotRight
    @NotStyleR:
    dey
    bne @NotLevelR
      inc VirusLevel,x
      lda VirusLevel,x
      cmp #81
      bne :+
        lda #1
        sta VirusLevel,x
      :
      ; Level
      jmp @NotRight
    @NotLevelR:

    dey
    bne @NotSpeedR
      ; Speed
      inc PuzzleSpeed,x
      lda PuzzleSpeed,x
      cmp #3
      bne :+
        lda #0
        sta PuzzleSpeed,x
      :
      jmp @NotRight
    @NotSpeedR:

    dey
    bne @NotGravityR
      ; Gravity
      inc PuzzleGravitySpeed,x
      lda PuzzleGravitySpeed,x
      cmp #3
      bne :+
        lda #0
        sta PuzzleGravitySpeed,x
      :
      jmp @NotRight
    @NotGravityR:

    dey
    bne @NotThemeR
      inc PuzzleTheme
      lda PuzzleTheme
      cmp #6
      bcc :+
        lda #0
        sta PuzzleTheme
      :
      jmp @NotRight
    @NotThemeR:

    inc PuzzleMusicChoice
    lda PuzzleMusicChoice
    and #3
    sta PuzzleMusicChoice
  @NotRight:
  rts

PutDecimal:
  lda BCD99,y
  pha
  lsr
  lsr
  lsr
  lsr
  ora #$30
  sta PPUDATA
  pla
  and #15
  ora #$30
  sta PPUDATA
  rts

PutSpeedName:
  asl
  tay
  lda PuzzleSpeedNames+0,y
  sta PPUDATA
  lda PuzzleSpeedNames+1,y
  sta PPUDATA
  rts

PuzzleSpeedNames:
  .byt "LoMdHi"

PuzzleGimmickNames:
  .byt "Classic "
  .byt "FreeSwap"
  .byt "Doubles "
  .byt "No Rush "
  .byt "Loose   "

PuzzleThemeNames:
  .byt "Minimal "
  .byt "Shapes  "
  .byt "Squirrel"

PuzzleMusicNames:
  .byt "Mute "
  .byt "SFX  "
  .byt "Tonic"
  .byt "Balmy"
.endproc
