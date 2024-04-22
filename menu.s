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

.proc TitleScreen
  CursorY = TitleCursorY

  jsr ClearName
  jsr ClearNameRight

  ; Set up a pause screen on the other tilemap so I can scroll to it at any time
  PositionXY 1, 16-6/2, 13
  jsr PutStringImmediate
  .byt "PAUSED",0
  PositionXY 1, 16-22/2, 16
  jsr PutStringImmediate
  .byt "Press Start to unpause",0
  ; Mark the pause screen with the playfield palette to avoid black text on black background when using a dark theme
  lda #$27
  sta PPUADDR
  lda #$C0
  sta PPUADDR
  lda #255
  ldx #64
: sta PPUDATA
  dex
  bne :-

  PositionXY 0, 6, 4
  jsr PutStringImmediate
  .byt "- Squirrel Domino -",0

  ; ---------------------------------------------
  ; Menu border
  ; Top
  PositionXY 0, 7, 16
  lda #$98
  sta PPUDATA
  lda #$99
  ldx #16
  jsr WritePPURepeated
  lda #$9a
  sta PPUDATA
  ; Bottom
  PositionXY 0, 7, 28
  lda #$9d
  sta PPUDATA
  lda #$9e
  ldx #16
  jsr WritePPURepeated
  lda #$9f
  sta PPUDATA

  ; Make sides
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_DOWN
  sta PPUCTRL
  PositionXY 0, 7, 17
  lda #$9b
  ldx #11
  jsr WritePPURepeated
  PositionXY 0, 24, 17
  lda #$9c
  ldx #11
  jsr WritePPURepeated
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_RIGHT
  sta PPUCTRL
  ; ---------------------------------------------
  PositionXY 0, 11, 18
  jsr PutStringImmediate
  .byt "Solo mode",0

  PositionXY 0, 11, 20
  jsr PutStringImmediate
  .byt "Versus mode",0

  PositionXY 0, 11, 22
  jsr PutStringImmediate
  .byt "How to play",0

  PositionXY 0, 11, 24
  jsr PutStringImmediate
  .byt "Credits",0

  PositionXY 0, 11, 26
  jsr PutStringImmediate
  .byt "Quit",0
  ; ---------------------------------------------

  jsr ClearOAM
  jsr WaitVblank
  lda #BG_ON|OBJ_ON
  sta PPUMASK
  lda #2
  sta OAM_DMA
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
TitleLoop:
  lda retraces
  lsr
  and #15
  tax
  lda BounceTable,x
  add #9*8-2
  sta OAM_XPOS
  lda CursorY
  asl
  asl
  asl
  asl
  adc #18*8-1
  sta OAM_YPOS
  lda #1
  sta OAM_TILE
  lda #OAM_COLOR_0
  sta OAM_ATTR

  jsr WaitVblank
  lda #2
  sta OAM_DMA

  jsr PuzzleReadJoy
  ldx #0
  jsr KeyRepeat

  lda key_new_or_repeat
  and #KEY_UP
  beq :+
    dec CursorY
    bpl :+
      lda #4
      sta CursorY
  :

  lda key_new_or_repeat
  and #KEY_DOWN
  beq :+
    inc CursorY
    lda CursorY
    cmp #5
    bne :+
      lda #0
      sta CursorY
  :

  lda keynew
  and #KEY_START|KEY_A
  beq :+
    lda CursorY
    asl
    tax
    lda OptionTable+1,x
    pha
    lda OptionTable+0,x
    pha
    rts
  :

  jmp TitleLoop

::BounceTable:
  .byt 1, 2, 3, 4
  .byt 5, 5, 5, 5
  .byt 4, 3, 2, 1
  .byt 0, 0, 0, 0

OptionTable:
.raddr OptionSolo
.raddr OptionVersus
.raddr OptionHowToPlay
.raddr OptionCredits
.raddr OptionQuit

OptionSolo:
  lda #0
  sta PuzzleVersus
  jmp PuzzleGameMenu
OptionVersus:
  lda #128
  sta PuzzleVersus
  jmp PuzzleGameMenu

OptionQuit:
  jmp ($FFFC)
.endproc

.proc OptionHowToPlay
  jsr WaitVblank
  lda #0
  sta PPUMASK
  lda #2
  sta OAM_DMA

  lda #' '
  jsr ClearNameCustom
  jsr ClearOAM

  PositionXY 0, 6, 4
  jsr PutStringImmediate
  .byt "--- How to play! ---",0

  PositionXY 0, 3, 6
  jsr PutStringImmediate
  .byt "Guide ",$82,$93," to make lines of",0

  PositionXY 0, 3, 8
  jsr PutStringImmediate
  .byt "4 or more. Clear out all ",$88,0

  PositionXY 0, 3, 10
  jsr PutStringImmediate
  .byt "to win!",0

  PositionXY 0, 3, 14
  jsr PutStringImmediate
  .byt "In versus mode it's a race",0

  PositionXY 0, 3, 16
  jsr PutStringImmediate
  .byt "against the other player to",0

  PositionXY 0, 3, 18
  jsr PutStringImmediate
  .byt "clear all ",$88," first!",0

  PositionXY 0, 5, 22
  jsr PutStringImmediate
  .byt "+: Move    A/B: Rotate",0

  PositionXY 0, 5, 26
  jsr PutStringImmediate
  .byt "Press Start to exit",0

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

WaitForExit:
  jsr WaitVblank
  lda #BG_ON
  sta PPUMASK
  jsr PuzzleReadJoy
  lda keynew
  and #KEY_A|KEY_START
  beq WaitForExit

  jsr WaitVblank
  lda #0
  sta PPUMASK
  jmp TitleScreen
.endproc

.proc OptionCredits
  jsr WaitVblank
  lda #0
  sta PPUMASK

  lda #' '
  jsr ClearNameCustom
  jsr ClearOAM

  PositionXY 0, 6, 4
  jsr PutStringImmediate
  .byt "----- Credits! -----",0

  PositionXY 0, 3, 6
  jsr PutStringImmediate
  .byt "Code & art by NovaSquirrel:",0
  PositionXY 0, 3, 8
  jsr PutStringImmediate
  .byt "https://novasquirrel.com/",0

  PositionXY 0, 3, 12
  jsr PutStringImmediate
  .byt "Music by maple syrup:",0
  PositionXY 0, 3, 14
  jsr PutStringImmediate
  .byt "https://maple.pet/",0
  PositionXY 0, 3, 16
  jsr PutStringImmediate
  .byt "Engine: FamiTone2 by Shiru",0

  PositionXY 0, 3, 20
  jsr PutStringImmediate
  .byt "Font by PinoBatch:",0
  PositionXY 0, 3, 22
  jsr PutStringImmediate
  .byt "https://pineight.com/",0

  PositionXY 0, 5, 26
  jsr PutStringImmediate
  .byt "Press Start to exit",0

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL

WaitForExit:
  jsr WaitVblank
  lda #BG_ON
  sta PPUMASK

  jsr PuzzleReadJoy
  lda keynew
  and #KEY_A|KEY_START
  beq WaitForExit

  jsr WaitVblank
  lda #0
  sta PPUMASK
  jmp TitleScreen
.endproc

.proc PuzzleGameMenu
  CursorY = TempVal ; array of 2

  jsr WaitVblank
  lda #0
  sta PPUMASK

  jsr ReseedRandomizer

  lda #2
  sta PuzzleMusicChoice
  lda #2
  sta PuzzlePieceTheme
  lda #0
  sta PuzzlePieceColor
  sta PuzzleBGTheme

  ; Clear RAM
  ldx #0
  tax
: sta PuzzleMap,x
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
  lda #0

  jsr PuzzleMusicInit

  lda PuzzleMusicChoice
  bne :+
    lda #0
    jsr FamiToneMusicPlay
  :

  ; Turn off screen and draw the menu
  jsr WaitVblank
  ldx #0
  stx PPUMASK

  ; Reset the background color to a light blue
  lda #$3f
  sta PPUADDR
  stx PPUADDR ; X is zero still from above
  lda #$31
  sta PPUDATA


  jsr ClearName
  jsr ClearOAM


  ; Menu border
  ; Top
  PositionXY 0, 4, 7
  lda #$98
  sta PPUDATA
  lda #$99
  ldx #21
  jsr WritePPURepeated
  lda #$9a
  sta PPUDATA
  ; Bottom
  PositionXY 0, 4, 25
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
  PositionXY 0, 4, 8
  lda #$9b
  ldx #17
  jsr WritePPURepeated
  PositionXY 0, 26, 8
  lda #$9c
  ldx #17
  jsr WritePPURepeated
  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_RIGHT
  sta PPUCTRL


  ; Draw the menu options
  PositionXY 0, 6, 4
  jsr PutStringImmediate
  .byt "- Squirrel Domino -",0

  ; -----------------------------------

  PositionXY 0, 12, 6
  lda PuzzleVersus
  bpl :+
;  bmi :+
;    jsr PutStringImmediate
;    .byt " Solo",0
;    jmp :++
;  :
    jsr PutStringImmediate
    .byt "Versus!",0
  :

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
  .byt "Piece: ",0

  PositionXY 0, 6, 19
  jsr PutStringImmediate
  .byt "Color: ",0

  PositionXY 0, 6, 21
  jsr PutStringImmediate
  .byt "Theme: ",0

  PositionXY 0, 6, 23
  jsr PutStringImmediate
  .byt "Sound: ",0

  ; -----------------------------------

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  sta CursorY+0
  sta CursorY+1
  sta PlayerReady+0
  sta PlayerReady+1

Loop:
  jsr WaitVblank
  lda #BG_ON|OBJ_ON
  sta PPUMASK
  lda #2
  sta OAM_DMA

  ; -------------------------------------------------------

  ; Piece colors
  lda #$3f
  sta PPUADDR
  lda #$1d
  sta PPUADDR
  jsr WritePieceColors

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

  ; Print piece theme name
  ; always 8 characters
  PositionXY 0, 13, 17
  lda PuzzlePieceTheme
  asl
  asl
  asl
  tax
  ldy #8
: lda PuzzlePieceThemeNames,x
  sta PPUDATA
  inx
  dey
  bne :-

  ; Print piece color number
  PositionXY 0, 13, 19
  lda PuzzlePieceColor
  add #'1'
  sta PPUDATA

  ; Print theme name
  ; always 8 characters
  PositionXY 0, 13, 21
  lda PuzzleBGTheme
  asl
  asl
  asl
  tax
  ldy #8
: lda PuzzleBGThemeNames,x
  sta PPUDATA
  inx
  dey
  bne :-

  ; Draw light or dark
  ldy #$91 ; light
  lda PuzzleBGTheme
  lsr
  bcc :+
    ldy #$81 ; dark
  :
  sty PPUDATA

  ; Music names
  PositionXY 0, 13, 23
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

  ; -------------------------------------------------------

  jsr PuzzleReadJoy
  ldx #0
  jsr KeyRepeat
  jsr RandomByte ; Step player 1's randomizer forward. Player 2's will just be a copy of player 1's
  inx
  jsr KeyRepeat

  bit PuzzleVersus ; If it's solo, don't allow player 2 to use the menu
  bmi :+
    lda #0
    sta key_new_or_repeat+1
    sta keynew+1
  :

  jsr ClearOAM

  ldx #0
  jsr RunMenu
  inx
  jsr RunMenu

  ; Allow starting the game or returning to the menu
  lda PlayerReady+0
  add PlayerReady+1
  cmp #2
  bne NotBothReady
    ldy #0 ; For the OAM index
    jsr ShowPiecePreviewSprites
    jsr WaitVblank
    PositionXY 0, 10, 6
    jsr PutStringImmediate
    .byt "Get ready!!",0
    lda #0
    sta PPUSCROLL
    sta PPUSCROLL

    lda #0
  : pha
    jsr WaitVblank
    lda #2
    sta OAM_DMA
    jsr FamiToneUpdate

    lda #4*5
    sta OamPtr
    lda #6*8
    jsr ReadySprite
    lda #22*8
    jsr ReadySprite

    pla
    add #1
    sta 255
    cmp #30
    bne :+
      lda #PuzzleSFX::CLEAR
      ldx #FT_SFX_CH0
      jsr FamiToneSfxPlay
    :

    lda 255
    cmp #60
    bne :--
  JumpToInitPuzzleGame:
    jmp InitPuzzleGame
  NotBothReady:

  ; In solo mode, player 1 can start the game on their own
  lda PuzzleVersus
  bne :+
    lda #0
    .repeat ::SCORE_LENGTH, I
      sta PlayerScore+I
    .endrep
    lda PlayerReady
    bne JumpToInitPuzzleGame
  :

  jsr FamiToneUpdate

  lda keynew
  and #KEY_B
  beq :+
    jsr WaitVblank
    lda #0
    sta PPUMASK
    jmp TitleScreen
  :

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
  bit PuzzleVersus
  bmi :+
    lda #$1
    sta OAM_TILE+0,y
    lda #$f0
    sta OAM_YPOS+4,y
  :
  lda #$42
  sta OAM_TILE+4,y

  lda #OAM_COLOR_0
  sta OAM_ATTR+0,y
  sta OAM_ATTR+4,y

  ; ---------------------------------------------
  ; Draw the piece preview
  jsr ShowPiecePreviewSprites

  tya
  add #4*5
  sta OamPtr

  lda PlayerReady+0
  beq Player1NotReady
    lda #6*8
    jsr ReadySprite
  Player1NotReady:

  lda PlayerReady+1
  beq Player2NotReady
    lda #22*8
    jsr ReadySprite
  Player2NotReady:

  jmp Loop

ShowPiecePreviewSprites:
  ldx PuzzlePieceTheme
  lda PieceThemeTileBases,x
  sta 0

  lda #$80 | PuzzleTiles::SINGLE
  ora 0
  sta OAM_TILE+8+(4*0),y
  lda #$88 | PuzzleTiles::SINGLE
  ora 0
  sta OAM_TILE+8+(4*1),y
  lda #$90 | PuzzleTiles::SINGLE
  ora 0
  sta OAM_TILE+8+(4*2),y

  lda #OAM_COLOR_3
  sta OAM_ATTR+8+(4*0),y
  sta OAM_ATTR+8+(4*1),y
  sta OAM_ATTR+8+(4*2),y

  lda #19*8-1
  sta OAM_YPOS+8+(4*0),y
  sta OAM_YPOS+8+(4*1),y
  sta OAM_YPOS+8+(4*2),y
  lda #15*8
  sta OAM_XPOS+8+(4*0),y
  lda #17*8
  sta OAM_XPOS+8+(4*1),y
  lda #19*8
  sta OAM_XPOS+8+(4*2),y
  rts

ReadySprite:
  ldy OamPtr
  sta OAM_XPOS+(4*0),y
  add #8
  sta OAM_XPOS+(4*1),y
  adc #8
  sta OAM_XPOS+(4*2),y

  lda #3
  sta OAM_TILE+(4*0),y
  lda #4
  sta OAM_TILE+(4*1),y
  lda #5
  sta OAM_TILE+(4*2),y

  lda #OAM_COLOR_0
  sta OAM_ATTR+(4*0),y
  sta OAM_ATTR+(4*1),y
  sta OAM_ATTR+(4*2),y

  lda retraces
  lsr
  and #15
  tax
  lda BounceTable,x
  eor #255
  add #6*8-1
  sta OAM_YPOS+(4*0),y
  sta OAM_YPOS+(4*1),y
  sta OAM_YPOS+(4*2),y

  tya
  add #12
  sta OamPtr
  rts

ShiftCursorY:
  asl
  asl
  asl
  asl
  add #9*8-1
  rts

RunMenu:
  lda key_new_or_repeat,x
  and #KEY_UP
  beq :+
    dec CursorY,x
    bpl :+
      lda #7
      sta CursorY,x
  :

  lda key_new_or_repeat,x
  and #KEY_DOWN
  beq :+
    inc CursorY,x
    lda CursorY,x
    cmp #8
    bne :+
      lda #0
      sta CursorY,x
  :

  lda key_new_or_repeat,x
  and #KEY_LEFT
  beq @NotLeft
    ldy CursorY,x
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
    bne @NotPieceThemeL
      dec PuzzlePieceTheme
      bpl :+
        lda #2
        sta PuzzlePieceTheme
      :
      jmp @NotLeft
    @NotPieceThemeL:

    dey
    bne @NotPieceColorL
      dec PuzzlePieceColor
      bpl :+
        lda #3
        sta PuzzlePieceColor
      :
      jmp @NotLeft
    @NotPieceColorL:

    dey
    bne @NotBGThemeL
      dec PuzzleBGTheme
      bpl :+
        lda #3
        sta PuzzleBGTheme
      :
      jmp @NotLeft
    @NotBGThemeL:

    dec PuzzleMusicChoice
    lda PuzzleMusicChoice
    and #3
    sta PuzzleMusicChoice
  @NotLeft:

  lda key_new_or_repeat,x
  and #KEY_RIGHT
  jeq @NotRight
    ldy CursorY,x
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
    bne @NotPieceThemeR
      inc PuzzlePieceTheme
      lda PuzzlePieceTheme
      cmp #3
      bne :+
        lda #0
        sta PuzzlePieceTheme
      :
      jmp @NotRight
    @NotPieceThemeR:

    dey
    bne @NotPieceColorR
      inc PuzzlePieceColor
      lda PuzzlePieceColor
      cmp #4
      bne :+
        lda #0
        sta PuzzlePieceColor
      :
      jmp @NotRight
    @NotPieceColorR:

    dey
    bne @NotBGThemeR
      inc PuzzleBGTheme
      lda PuzzleBGTheme
      cmp #4
      bne :+
        lda #0
        sta PuzzleBGTheme
      :
      jmp @NotRight
    @NotBGThemeR:

    inc PuzzleMusicChoice
    lda PuzzleMusicChoice
    and #3
    sta PuzzleMusicChoice
  @NotRight:

  lda keynew,x
  and #KEY_START
  beq NoStart
    lda PlayerReady,x
    eor #1
    sta PlayerReady,x

    beq NoStart
    lda #PuzzleSFX::LAND
    ldx #FT_SFX_CH0
    jsr FamiToneSfxPlay
  NoStart:
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

PuzzlePieceThemeNames:
  .byt "Minimal "
  .byt "Shapes  "
  .byt "Squirrel"

PuzzleBGThemeNames:
  .byt "Paws    "
  .byt "Paws    "
  .byt "Paws    "
  .byt "Paws    "

PuzzleMusicNames:
  .byt "Mute "
  .byt "SFX  "
  .byt "Tonic"
  .byt "Balmy"
.endproc
