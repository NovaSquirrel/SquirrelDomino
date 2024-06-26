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

; input: X = Player number
; output: A = Random number (0, 1, or 2)
.proc PuzzleRandomColor
: jsr RandomByte
  and #3
  cmp #3
  beq :-
  rts
.endproc

.proc PuzzleRandomInit
  ldx #PUZZLE_RANDBUF_SIZE - 1
Loop:
  txa

  ; Constrain the piece to only 0-8
: cmp #9 ; 
  bcc :+ ; Exit if small enough
  sbc #9 ; Carry is already set, so no SEC
  bpl :-
:

  ; Store it to both players' RandBufs
  sta PuzzleRandBuf,x
  sta PuzzleRandBuf+PUZZLE_RANDBUF_SIZE,x
  dex
  bpl Loop

  ; X is still zero
  stx PuzzleRandPos+0
  stx PuzzleRandPos+1

::CopyP1RandomToP2:
  ; Copy player 1's random state to player 2's
  lda random0+0
  sta random0+1
  lda random1+0
  sta random1+1
  lda random2+0
  sta random2+1
  lda random3+0
  sta random3+1
  rts
.endproc

; input: X = Player number
.proc PuzzlePrescription ; get the next pill for player X
SwapTarget = 0
PlayerPos = 1
Chosen = 2
  ; Get the player position
  lda PlayerSelect,x
  add PuzzleRandPos,x
  sta PlayerPos

  ; Select the swap target
  jsr RandomByte
  and #15
  add PuzzleRandPos,x
  ; And keep it within the circular buffer
  cmp #PUZZLE_RANDBUF_SIZE
  bcc :+
    sbc #PUZZLE_RANDBUF_SIZE ; Carry is already set
  :
  ; Pick the right queue
  add PlayerSelect,x
  sta SwapTarget

  ; Swap SwapTarget with PlayerPos
  tay
  lda PuzzleRandBuf,y
  pha
  pha
  ldy PlayerPos
  lda PuzzleRandBuf,y
  ldy SwapTarget
  sta PuzzleRandBuf,y
  pla
  ldy PlayerPos
  sta PuzzleRandBuf,y
  pla
  tay

  ; Increase the position
  inc PuzzleRandPos,x
  lda PuzzleRandPos,x
  cmp #PUZZLE_RANDBUF_SIZE
  bcc :+
    lda #0
    sta PuzzleRandPos,x
  :

  ; Get the two pill colors
  lda OutcomeListA,y
  sta 0
  lda OutcomeListB,y
  sta 1
  rts

; All of the possible outcomes for pills
OutcomeListA:
  .byt 0, 0, 0, 1, 1, 1, 2, 2, 2
OutcomeListB:
  .byt 0, 1, 2, 0, 1, 2, 0, 1, 2

PlayerSelect:
  .byt 0, PUZZLE_RANDBUF_SIZE
.endproc

; X = Player number
.proc PuzzleDoPlayer
  ; -----------------------------------

  ; Draw the next piece
  ldy OamPtr

  lda #(12+3)*8
  add PuzzleXSpriteOffset,x
  sta OAM_XPOS+0,y
  lda #(12+4)*8
  add PuzzleXSpriteOffset,x
  sta OAM_XPOS+4,y

  lda #4*8-1
  sta OAM_YPOS+0,y
  sta OAM_YPOS+4,y

  ; Calculate the tiles for first and second pieces of the pill
  lda PuzzleNextColor1,x
  asl
  asl
  asl
  ora #$80 | PuzzleTiles::LEFT
  ora PuzzleTileBase
  sta OAM_TILE+0,y

  lda PuzzleNextColor2,x
  asl
  asl
  asl
  ora #$80 | PuzzleTiles::RIGHT
  ora PuzzleTileBase
  sta OAM_TILE+4,y

  lda #OAM_COLOR_3
  sta OAM_ATTR+0,y
  sta OAM_ATTR+4,y

  tya
  add #8
  sta OamPtr

  ; -----------------------------------

  ldy PuzzleState,x
  lda StateHi,y
  pha
  lda StateLo,y
  pha
  rts

StateHi:
  .hibytes PuzzleInit-1, InitPill-1, FallPill-1, PuzzleMatch-1, PuzzleGravity-1, PuzzleVictory-1, PuzzleFailure-1
StateLo:
  .lobytes PuzzleInit-1, InitPill-1, FallPill-1, PuzzleMatch-1, PuzzleGravity-1, PuzzleVictory-1, PuzzleFailure-1
.endproc

; X = Player number
.proc PuzzleReceiveGarbage
  ; Receive garbage if necessary
  lda PuzzleGarbageCount,x
  beq NoReceiveGarbage
    lda #PuzzleSFX::GARBAGE
    jsr PuzzlePlaySFX

    .scope
    Column = 0
    Row = 1
    Tile = 2
    inc PuzzleRedraw,x

    ; Make the new tiles start falling
    lda #PuzzleStates::GRAVITY
    sta PuzzleState,x

    ; Get index to garbage colors
    txa
    asl
    asl
    sta TempY

  PutGarbageLoop:
    ldy TempY
    lda PuzzleGarbageColor,y
    sta Tile
    iny
    sty TempY

    jsr RandomByte
    and #7
    sta Column
    lda #0
    sta Row
    
    ; Make sure this space isn't already taken, and move to a different column if it is
    jsr PuzzleGridRead
    beq XOkay

    lda Column
    eor #4
    sta Column
    jsr PuzzleGridRead
    beq XOkay

    lda Column
    eor #2
    sta Column
    jsr PuzzleGridRead
    beq XOkay

    lda Column
    eor #1
    sta Column
    jsr PuzzleGridRead
    bne NextGarbage ; Skip if it can't.
    ; Really this should always work though.

  XOkay:
    lda Tile
    sta PuzzleMap,y

  NextGarbage:
    dec PuzzleGarbageCount,x
    bne PutGarbageLoop

    ; Don't return to the previous routine
    pla
    pla
    rts
    .endscope
  NoReceiveGarbage:
  rts
.endproc


.proc InitPill
  ; Send the other player garbage if needed
  lda PuzzleMatchesMade,x
  cmp #2
  bcc NoSendGarbage
    ; Don't send garbage if they already have some
    jsr PuzzleOtherPlayer

    lda PuzzleGarbageCount,y
    bne NoSendGarbage
      lda PuzzleMatchesMade,x
      sta PuzzleGarbageCount,y

      ; Preserve X, but multiply it by 4 for now
      stx TempX
      txa
      asl
      asl
      tax

      ; Multiply Y by four
      tya
      asl
      asl
      tay

      ; Copy over the four colors
      lda PuzzleMatchColor+0,x 
      sta PuzzleGarbageColor+0,y
      lda PuzzleMatchColor+1,x
      sta PuzzleGarbageColor+1,y
      lda PuzzleMatchColor+2,x
      sta PuzzleGarbageColor+2,y
      lda PuzzleMatchColor+3,x
      sta PuzzleGarbageColor+3,y

      ldx TempX
  NoSendGarbage:

  jsr PuzzleReceiveGarbage

  ; In swap mode, go right to falling pill mode instead of reinitializing the pill
  lda PuzzleSwapMode,x
  beq :+
    lda #PuzzleStates::FALL_PILL
    sta PuzzleState,x
    rts
  :

  ; Color = next color
  lda PuzzleNextColor1,x
  sta PuzzleColor1,x
  lda PuzzleNextColor2,x
  sta PuzzleColor2,x

  ; Choose a new next color
  jsr PuzzlePrescription
  lda 0
  sta PuzzleNextColor1,x
  lda 1
  sta PuzzleNextColor2,x

  lda PuzzleGimmick
  cmp #PuzzleGimmicks::DOUBLES
  bne :+
    lda PuzzleNextColor1,x
    sta PuzzleNextColor2,x
  :

  lda #3
  sta PuzzleX,x
  lda #0
  sta PuzzleY,x
  sta PuzzleDir,x
  sta PuzzleMatchesMade,x
  sta PuzzleVirusesClearedThisMove,x

  ; Move into falling pill mode
  inc PuzzleState,x

  ldy PuzzleSpeed,x
  ; Give extra time after the pill appears
  lda #50
  sta PuzzleFallTimer,x
  ; And even more time if it's the first pill and it's versus mode
  lda PuzzleVersus
  bpl :+
  lda PlayerReady,x
  beq :+
    asl PuzzleFallTimer,x
    lda #0
    sta PlayerReady,x
  :

  ; If there's a tile in either of the two opening tiles
  ; then you've lost.
  ldy PuzzlePlayfieldBase
  lda PuzzleMap+3*PUZZLE_HEIGHT,y
  ora PuzzleMap+4*PUZZLE_HEIGHT,y
  beq NotFailure
      lda #PuzzleSFX::FAIL
      jsr PuzzlePlaySFX
      stx TempX
      sty TempY
      jsr FamiToneMusicStop
      ldy TempY
      ldx TempX

      ldy PuzzlePlayfieldBase
      ; "Oops" message
      lda #$10
      sta PuzzleMap+PUZZLE_HEIGHT*2,y
      lda #$11
      sta PuzzleMap+PUZZLE_HEIGHT*3,y
      lda #$12
      sta PuzzleMap+PUZZLE_HEIGHT*4,y
      lda #$13
      sta PuzzleMap+PUZZLE_HEIGHT*5,y
      lda #0
      sta PuzzleMap+PUZZLE_HEIGHT*0,y
      sta PuzzleMap+PUZZLE_HEIGHT*1,y
      sta PuzzleMap+PUZZLE_HEIGHT*6,y
      sta PuzzleMap+PUZZLE_HEIGHT*7,y

      lda #60
      sta PuzzleFallTimer,x

      lda #PuzzleStates::FAILURE
      sta PuzzleState,x
      inc PuzzleRedraw,x

      jsr PuzzleOtherPlayer
      jsr ScorePointForPlayerY
  NotFailure:
  rts
.endproc

PuzzleFallSpeeds: ; pill speed
  .byt 60, 30, 15
PuzzleGravitySpeeds: ; gravity speeds
  .byt 16, 8, 2

.proc FallPill
Tile1 = TouchTemp + 0
Tile2 = TouchTemp + 1
SecondX = TouchTemp + 2 ; second tile X
SecondY = TouchTemp + 3 ; second tile Y
GhostY = TouchTemp + 4

  lda keynew,x
  and #KEY_SELECT
  beq :+
    lda PuzzleGimmick
    cmp #PuzzleGimmicks::FREE_SWAP
    bne :+
    lda PuzzleX,x
    sta PuzzleSwapX,x
    lda PuzzleY,x
    sta PuzzleSwapY,x

    lda PuzzleSwapMode,x
    eor #1
    sta PuzzleSwapMode,x
  :
  lda PuzzleSwapMode,x
  jne PuzzleInSwapMode

  ; Get the pre-rotate X and Y for the second tile
  ; Backup this information in case the game needs to restore it
  lda PuzzleX,x
  sta TempX
  lda PuzzleY,x
  sta TempY
  lda PuzzleDir,x
  sta PlayerDir
  lda PuzzleColor1,x
  sta TempVal+0
  lda PuzzleColor2,x
  sta TempVal+1

  ; ---------------
  ; Allow rotation
  ; ---------------

  ; Rotate
  lda keynew,x
  and #KEY_B
  beq NotB
    inc PuzzleDir,x
    lda PuzzleDir,x
    cmp #2
    bne NotB
      lda #0
      sta PuzzleDir,x
      jsr SwapColors
  NotB:

  ; Rotate
  lda keynew,x
  and #KEY_A
  beq NotA
    dec PuzzleDir,x
    bpl NotA
      lda #1
      sta PuzzleDir,x
      jsr SwapColors
  NotA:

  ; Get the X and Y for the second piece
  ; so it's already fetched
  jsr CalculateSecondXY

  lda PuzzleY,x
  bne :+
    lda PuzzleDir,x
    beq :+
      lda PuzzleX,x
      sta SecondX
      lda PuzzleY,x
      sta SecondY
  :


  ; Slide left or right to move out of the way when rotating
  ; First try moving right
  jsr PuzzleGridReadSecond
  bne :+
  jsr PuzzleGridReadFirst
  beq :++
  :
    ; Both tiles free to the right?
    lda PuzzleX,x
    sta 0
    inc 0
    lda PuzzleY,x
    sta 1
    jsr PuzzleGridRead
    bne :+

    lda SecondX
    sta 0
    inc 0
    lda SecondY
    sta 1
    jsr PuzzleGridRead
    bne :+

    inc PuzzleX,x
    inc SecondX
  :

  ; Move left out of things
  jsr PuzzleGridReadSecond
  bne :+
  jsr PuzzleGridReadFirst
  beq :++
  :
    ; Both tiles free to the left?
    lda PuzzleX,x
    beq :+
    sta 0
    dec 0
    lda PuzzleY,x
    sta 1
    jsr PuzzleGridRead
    bne :+

    lda SecondX
    sta 0
    dec 0
    lda SecondY
    sta 1
    jsr PuzzleGridRead
    bne :+

    dec PuzzleX,x
    dec SecondX
  :

  ; ---------------
  ; Allow moving horizontally
  ; ---------------

  lda key_new_or_repeat,x
  and #KEY_LEFT
  beq NotLeft
    lda PuzzleX,x
    beq NotLeft
      dec PuzzleX,x
      dec SecondX
  NotLeft:

  ; Don't allow moving into things to the left
  jsr PuzzleGridReadSecond
  bne :+
  jsr PuzzleGridReadFirst
  beq :++
  :
    inc PuzzleX,x
    inc SecondX
  :

  lda key_new_or_repeat,x
  and #KEY_RIGHT
  beq NotRight
    inc PuzzleX,x
    inc SecondX
  NotRight:

  ; Don't allow moving into things to the right
  jsr PuzzleGridReadSecond
  bne :+
  jsr PuzzleGridReadFirst
  beq :++
  :
    dec PuzzleX,x
    dec SecondX
  :

  ; Correct if you go past the right edge
  ; either by rotating or by moving right
  lda SecondX
  cmp #PUZZLE_WIDTH
  bne :+
    dec PuzzleX,x
    dec SecondX
  :

  ; If after all of this, the pill is still stuck in something, disallow the rotation
  ; but swap the colors
  jsr PuzzleGridReadSecond
  bne :+
  jsr PuzzleGridReadFirst
  beq :++
  :
    lda TempX
    sta PuzzleX,x
    lda TempY
    sta PuzzleY,x
    lda PlayerDir
    sta PuzzleDir,x
    lda TempVal+0
    sta PuzzleColor2,x
    lda TempVal+1
    sta PuzzleColor1,x
    jsr CalculateSecondXY
  :

  ; Doing this later after the rotate so variables aren't corrupted
  lda keynew
  and #KEY_A|KEY_B
  beq :+
    lda #PuzzleSFX::ROTATE
    jsr PuzzlePlaySFX
  :

  ; Calculate the ghost piece placement
  lda PuzzleX,x
  sta 0  
  lda PuzzleY,x
  jsr GhostPieceShared
  sta GhostY

  ; Don't care about the second pill tile if it's vertical
  ; because it'll just be the same
  lda PuzzleDir,x
  bne @SkipGhostBecauseVertical

  lda SecondX
  sta 0  
  lda SecondY
  jsr GhostPieceShared
  cmp GhostY
  bcs :+
    sta GhostY
  :
@SkipGhostBecauseVertical:

  ; Hard drop
  lda keynew,x
  and #KEY_UP
  beq NoHardDrop

    lda PuzzleY,x
    cmp GhostY
    beq NoSmear
  HardDropSmear:
    ldy OamPtr
    lda PuzzleY,x
    add #6
    asl
    asl
    asl
    sta OAM_YPOS,y
 
    lda PuzzleX,x
    add #12
    asl
    asl
    asl
    add PuzzleXSpriteOffset,x
    sta OAM_XPOS,y

    ; Offset it a little if horizontal
    lda PuzzleDir,x
    lsr
    bcs :+
      lda PuzzleY,x
      lsr
      bcs :+
      lda OAM_XPOS,y
      add #8
      sta OAM_XPOS,y
    :

    lda #0
    sta OAM_ATTR,y
    lda #$50
    sta OAM_TILE,y
    iny
    iny
    iny
    iny
    sty OamPtr

    lda PuzzleY,x
    add #1
    cmp GhostY
    sta PuzzleY,x
    bne HardDropSmear
  NoSmear:

    lda #2
    sta PuzzleFallTimer,x
    lda GhostY
    sta PuzzleY,x
  NoHardDrop:

  ; If the ghost Y is the same as the pill Y, no ghost piece shown
  lda GhostY
  cmp PuzzleY,x
  bne :+
    lda #25
    sta GhostY
  :

  ; Turn off the lockout soft drop flag upon releasing Down
  lda keydown,x
  and #KEY_DOWN
  bne :+
    lda #0
    sta LockoutSoftDrop,x
  :

  ; Can't drop until they press down again
  lda LockoutSoftDrop,x
  bne :+
  ; Soft drop
  lda keydown,x
  and #KEY_DOWN
  beq :+
    ; Fall every other frame if holding down
    lda retraces
    lsr
    bcs ForceFall
  :

  lda PuzzleGimmick
  cmp #PuzzleGimmicks::NO_RUSH
  beq NoFall

  dec PuzzleFallTimer,x
  bne NoFall
ForceFall:
    inc PuzzleY,x
    inc SecondY
    ldy PuzzleSpeed,x
    lda PuzzleFallSpeeds,y
    sta PuzzleFallTimer,x

    lda PuzzleY,x
    cmp #PUZZLE_HEIGHT
    bne NoFall
  FallLandOnSomething:
     dec PuzzleY,x
     dec SecondY
     jmp LandOnSomething
  NoFall:

  ; Check if the pill has landed on another pill
  jsr PuzzleGridReadFirst
  sta 2
  jsr PuzzleGridReadSecond
  ora 2
  bne FallLandOnSomething

Draw:
  ; Draw the pill
  ; (First get info before Y is taken up by OAM index)
  ldy PuzzleDir,x
  lda SecondPiecePX,y
  sta 0
  lda SecondPiecePY,y
  sta 1

  ; Now draw it
  ldy OamPtr

  lda PuzzleX,x
  add #12
  asl
  asl
  asl
  add PuzzleXSpriteOffset,x
  sta OAM_XPOS+0,y
  add 0
  sta OAM_XPOS+4,y

  lda PuzzleY,x
  add #6
  asl
  asl
  asl
  sta OAM_YPOS+0,y
  add 1
  sta OAM_YPOS+4,y

  ; Calculate the tiles for first and second pieces of the pill
  jsr GetPillTiles
  lda Tile1
  sta OAM_TILE+0,y

  lda Tile2
  sta OAM_TILE+4,y

  lda #OAM_COLOR_3
  sta OAM_ATTR+0,y
  sta OAM_ATTR+4,y
  sta OAM_ATTR+8,y
  sta OAM_ATTR+12,y

  ; -----------------------------------

  ; Ghost tiles
  lda PuzzleX,x
  add #12
  asl
  asl
  asl
  add PuzzleXSpriteOffset,x
  sta OAM_XPOS+8,y
  add 0
  sta OAM_XPOS+12,y

  lda GhostY
  add #6
  asl
  asl
  asl
  sta OAM_YPOS+8,y
  add 1
  sta OAM_YPOS+12,y

  lda PuzzleColor1,x
  asl
  asl
  asl
  ora #$87
  sta OAM_TILE+8,y

  lda PuzzleColor2,x
  asl
  asl
  asl
  ora #$87
  sta OAM_TILE+12,y

  tya
  add #16
  sta OamPtr
  rts

SecondPiecePX: ; pixels
  .byt 8, 0
SecondPiecePY:
  .byt 0, <-8
SecondPieceTX: ; tiles
  .byt 1, 0
SecondPieceTY:
  .byt 0, <-1

FirstPieceTile:
  .byt $82, $84 
SecondPieceTile:
  .byt $83, $85

GhostPieceShared:
  sta 1
: jsr PuzzleGridRead
  bne :+
  inc 1 
  lda 1
  cmp #PUZZLE_HEIGHT
  bcc :-
: dec 1
  lda 1
  rts

SwapColors:
  lda PuzzleColor1,x
  pha
  lda PuzzleColor2,x
  sta PuzzleColor1,x
  pla
  sta PuzzleColor2,x
  rts

CalculateSecondXY:
  ldy PuzzleDir,x
  lda SecondPieceTX,y
  add PuzzleX,x
  sta SecondX
  lda SecondPieceTY,y
  add PuzzleY,x
  sta SecondY
  rts


GetPillTiles:
  lda PuzzleDir,x
  asl
  add #$82
  ora PuzzleTileBase
  sta 2

  lda PuzzleColor1,x
  asl
  asl
  asl
  ora 2
  sta Tile1

  lda PuzzleColor2,x
  asl
  asl
  asl
  ora 2

  adc #1 ; carry is clear
  sta Tile2

  lda PuzzleGimmick
  cmp #PuzzleGimmicks::UNCONNECTED
  bne :+
    lda Tile1
    and #<~7
    ora #1
    sta Tile1

    lda Tile2
    and #<~7
    ora #1
    sta Tile2
  :

  rts

LandOnSomething:
  lda #PuzzleSFX::LAND
  jsr PuzzlePlaySFX

  lda #PuzzleStates::INIT_PILL
  sta PuzzleState,x

  lda #1
  sta LockoutSoftDrop,x

  jsr GetPillTiles
  lda PuzzleX,x
  sta 0
  lda PuzzleY,x
  sta 1
  lda Tile1
  jsr LandPillWrite
  lda SecondX
  sta 0
  lda SecondY
  sta 1
  lda Tile2

LandPillWrite:
  ; Push the color
  sta 2

  ; Ignore negative Y positions
  bit 1
  bpl :+
    rts
  :

  pha
  lda 0
  asl
  asl
  asl
  asl
  ora 1
  ora PuzzlePlayfieldBase
  tay
  pla
  ; Write to the internal grid
  sta PuzzleMap,y

  ; Update the nametable now

  ; Find a tile update slot
  ldy #0
: lda TileUpdateA1,y
  beq :+   ; found a free slot
  iny
  cpy #MaxNumTileUpdates 
  bne :-   ; keep going
  beq @Exit ; no slots? shouldn't happen but handle it anyway
:

  ; Form PPU address
  ; 4 is low half
  ; 5 is high half
  lda #0
  sta 5
  lda 1 ; Piece Y position
  .repeat 5 ; * 32
    asl
    rol 5
  .endrep
  add 0
  sta 4

  ; Write PPU address
  lda PPU_UpdateLo,x
  add 4
  sta TileUpdateA2,y
  lda PPU_UpdateHi,x
  adc 5
  sta TileUpdateA1,y

  ; Get tile
  lda 2
  sta TileUpdateT,y

@Exit:
  lda #PuzzleStates::CHECK_MATCH
  sta PuzzleState,x
  rts

PuzzleGridReadSecond:
  lda SecondX
  sta 0
  lda SecondY
  sta 1
  jmp PuzzleGridRead
.endproc


.proc PuzzleInSwapMode
  jsr PuzzleReceiveGarbage

  lda #24
  sta FallPill::GhostY

  lda key_new_or_repeat,x
  and #KEY_LEFT
  beq :+
    lda PuzzleSwapX,x
    beq :+
      dec PuzzleSwapX,x
  :

  lda key_new_or_repeat,x
  and #KEY_RIGHT
  beq :+
    lda PuzzleSwapX,x
    cmp #PUZZLE_WIDTH-2
    beq :+
      inc PuzzleSwapX,x
  :

  lda key_new_or_repeat,x
  and #KEY_UP
  beq :+
    lda PuzzleSwapY,x
    beq :+
      dec PuzzleSwapY,x
  :

  lda key_new_or_repeat,x
  and #KEY_DOWN
  beq :+
    lda PuzzleSwapY,x
    cmp #PUZZLE_HEIGHT-1
    beq :+
      inc PuzzleSwapY,x
  :

  ; -----------------------------------

  lda keynew,x
  and #KEY_A|KEY_B
  beq NotSwap
    lda PuzzleSwapX,x
    sta 0
    lda PuzzleSwapY,x
    sta 1
    jsr PuzzleGridRead
    ; There's a bit of a problem here because viruses are tile 0 in each set of 8 tiles per color
    ; so masking off the color gives you just 0-7 and empty tiles will also give you a zero.
    ; I don't want it to be able to swap with viruses.
    beq @EmptyOK ; Can swap with an empty tile
    and #7
    beq NotSwap
  @EmptyOK:
    sty 2

    inc 0 ; Try the tile to the right
    jsr PuzzleGridRead
    beq @EmptyOK2 ; Can swap with an empty tile
    and #7
    beq NotSwap
  @EmptyOK2:
    sty 3

    ; Swap the two tiles
    lda PuzzleMap,y
    pha
    ldy 2
    lda PuzzleMap,y
    ldy 3
    sta PuzzleMap,y
    pla
    ldy 2
    sta PuzzleMap,y

    inc PuzzleRedraw,x
    ldy PuzzleGravitySpeed,x
    lda PuzzleGravitySpeeds,y
    sta PuzzleFallTimer,x
    lda #PuzzleStates::GRAVITY
    sta PuzzleState,x
    rts
  NotSwap:

  ; -----------------------------------

  ; Draw the swap cursor
  ldy OamPtr
  lda PuzzleSwapX,x
  add #12
  asl
  asl
  asl
  add PuzzleXSpriteOffset,x
  sta OAM_XPOS+0,y
  add #8
  sta OAM_XPOS+4,y

  lda PuzzleSwapY,x
  add #6
  asl
  asl
  asl
  sub #1
  sta OAM_YPOS+0,y
  sta OAM_YPOS+4,y

  lda #OAM_COLOR_1
  sta OAM_ATTR+0,y
  sta OAM_ATTR+4,y

  lda #$50
  sta OAM_TILE+0,y
  sta OAM_TILE+4,y

  tya
  add #8
  sta OamPtr

  ; Draw the original piece too
  jmp FallPill::Draw
.endproc

PuzzleGridReadFirst:
  lda PuzzleX,x
  sta 0
  lda PuzzleY,x
  sta 1
.proc PuzzleGridRead
  lda 0 ; Column
  asl
  asl
  asl
  asl
  ora 1 ; Row
  ora PuzzlePlayfieldBase
  tay
  lda PuzzleMap,y
  rts
.endproc

.proc PuzzleMatch
COLOR_MASK = %11000
Row = 1
Column = 0
Color = 2
ClearTile = 3
PointsTemp = 4
  lda #0
  sta Row
  sta Column
Horizontal:
  jsr PuzzleGridRead
  sta Color
  and PuzzleMap+PUZZLE_HEIGHT*1,y
  and PuzzleMap+PUZZLE_HEIGHT*2,y
  and PuzzleMap+PUZZLE_HEIGHT*3,y
  beq NextHorizontal ; Skip if any of the next three are empty

  ; Check for four in a row
  lda Color
  and #COLOR_MASK
  sta Color

  lda PuzzleMap+PUZZLE_HEIGHT*1,y
  and #COLOR_MASK
  cmp Color
  bne NextHorizontal

  lda PuzzleMap+PUZZLE_HEIGHT*2,y
  and #COLOR_MASK
  cmp Color
  bne NextHorizontal

  lda PuzzleMap+PUZZLE_HEIGHT*3,y
  and #COLOR_MASK
  cmp Color
  bne NextHorizontal

  ; There is a match!
  jsr PrepareGarbage

  ; Clear the tiles
  lda Color
  ora #$86
  sta ClearTile
  sta PuzzleRedraw,x

  ; Clear out the whole line
: jsr AddPointsForVirus
  lda ClearTile
  sta PuzzleMap,y
  tya
  add #PUZZLE_HEIGHT
  tay
  inc Column
  lda Column
  cmp #PUZZLE_WIDTH
  bcs NextHorizontalRow
  lda PuzzleMap,y
  beq :+
  and #COLOR_MASK
  cmp Color
  beq :-
: ; Back up
  dec Column

NextHorizontal:
  ; Next column
  inc Column
  lda Column
  cmp #PUZZLE_WIDTH-3
  bcc Horizontal
NextHorizontalRow:
  ; Next row
  lda #0
  sta Column
  inc Row
  lda Row
  cmp #PUZZLE_HEIGHT
  bcc Horizontal

  ; -----------------------------------

  lda #0
  sta Row
  sta Column
Vertical:
  jsr PuzzleGridRead
  sta Color
  and PuzzleMap+1,y
  and PuzzleMap+2,y
  and PuzzleMap+3,y
  beq NextVertical ; Skip if any of the next three are empty

  ; Check for four in a row
  lda Color
  and #COLOR_MASK
  sta Color

  lda PuzzleMap+1,y
  and #COLOR_MASK
  cmp Color
  bne NextVertical

  lda PuzzleMap+2,y
  and #COLOR_MASK
  cmp Color
  bne NextVertical

  lda PuzzleMap+3,y
  and #COLOR_MASK
  cmp Color
  bne NextVertical

  ; There is a match!
  jsr PrepareGarbage

  ; Clear the tiles
  lda Color
  ora #$86
  sta ClearTile
  sta PuzzleRedraw,x

  ; Clear out the whole line
: jsr AddPointsForVirus
  lda ClearTile
  sta PuzzleMap,y
  iny
  inc Row
  lda Row
  cmp #PUZZLE_HEIGHT
  bcs NextVerticalColumn
  lda PuzzleMap,y
  beq :+
  and #COLOR_MASK
  cmp Color
  beq :-
: ; Back up
  dec Row

NextVertical:
  ; Next row
  inc Row
  lda Row
  cmp #PUZZLE_HEIGHT-3
  bcc Vertical
NextVerticalColumn:
  ; Next column
  lda #0
  sta Row
  inc Column
  lda Column
  cmp #PUZZLE_WIDTH
  bcc Vertical

  ; Go to init pill if nothing cleared
  ; but attempt gravity if it did
  lda #PuzzleStates::INIT_PILL
  sta PuzzleState,x

  lda PuzzleRedraw,x
  bne :+
   rts
  :
  ; Now attempt to make things fall
  lda #PuzzleStates::GRAVITY
  sta PuzzleState,x

  ldy PuzzleGravitySpeed,x
  lda PuzzleGravitySpeeds,y
  sta PuzzleFallTimer,x
  rts

PrepareGarbage:
  sty TempY

  ; Play the clear sound effect
  ; but back up the three temporary variables FamiTone uses
  lda 0
  pha
  lda 1
  pha
  lda 2
  pha
  ; Play three different clear sound effects
  ; but anything past three just uses the third one
  lda PuzzleMatchesMade,x
  cmp #2
  bcc :+
    lda #2
  :
  add #PuzzleSFX::CLEAR
  jsr PuzzlePlaySFX
  pla
  sta 2
  pla
  sta 1
  pla
  sta 0

  ; Don't send gabage in swap mode
  lda PuzzleSwapMode,x
  bne @_rts

  ; Ignore everything after the first four
  lda PuzzleMatchesMade,x
  cmp #4
  bcc :+
@_rts:
    rts
  :

  ; Y = Player*4 + Match count
  txa
  asl
  asl
  adc PuzzleMatchesMade,x
  tay

  ; Put a single tile in the array
  lda Color
  ora #$80 | PuzzleTiles::SINGLE
  ora PuzzleTileBase
  sta PuzzleMatchColor,y

  inc PuzzleMatchesMade,x
  ldy TempY
  rts

AddPointsForVirus:
  cpx #0 ; Player 0 only
  beq :+
    rts
  :
  lda PuzzleMap,y
  and #7
  cmp #PuzzleTiles::VIRUS
  bne @NotVirus
    sty TempY

    lda PuzzleSpeed
    asl
    asl
    asl
    sta PointsTemp
    lda PuzzleVirusesClearedThisMove
    ora PointsTemp
    tay
    lda OnesDigits,y
    adc PlayerScore+0 ; PuzzleSpeed is never high enough to set carry here
    sta PlayerScore+0
    lda TensDigits,y
    adc PlayerScore+1 ; Nor is PlayerScore
    sta PlayerScore+1
    lda HundredsDigits,y
    adc PlayerScore+2 ; Same for PlayerScore+1
    sta PlayerScore+2

    ;ldx #0 <-- Already known to be 0
  @FixUpScore:
    lda PlayerScore,x
    cmp #10
    bcc :+
      sbc #10
      sta PlayerScore,x
      inc PlayerScore+1,x
      bne @FixUpScore ; Retry again just in case
    :
    inx
    cpx #SCORE_LENGTH
    bne @FixUpScore

    jsr CheckAgainstHighScore

    ldy TempY
    ldx #0 ; Known to be player 0
    inc PuzzleVirusesClearedThisMove
    lda PuzzleVirusesClearedThisMove
    cmp #7
    bcc @NotVirus
    lda #7
    sta PuzzleVirusesClearedThisMove
  @NotVirus:
  rts
HundredsDigits: .byt 0, 0, 0, 0, 0, 0, 0, 1
                .byt 0, 0, 0, 0, 0, 0, 1, 2
                .byt 0, 0, 0, 0, 0, 0, 1, 3
TensDigits:     .byt 0, 0, 0, 0, 1, 3, 6, 2
                .byt 0, 0, 0, 1, 3, 6, 2, 5
                .byt 0, 0, 1, 2, 4, 9, 9, 8
OnesDigits:     .byt 1, 2, 4, 8, 6, 2, 4, 8
                .byt 2, 4, 8, 6, 2, 4, 8, 6
                .byt 3, 6, 2, 4, 8, 6, 2, 4
.endproc


.proc PuzzleGravity
  Column = 0
  Row = 1
  DidFix = 2 ; flag to say a tile was fixed
  VirusCount = 3 ; used to detect winning

  lda PuzzleFallTimer,x
  beq :+
    dec PuzzleFallTimer,x
    rts
  :

  lda #0
  sta DidFix
  sta VirusCount
  ldy PuzzlePlayfieldBase
FixLoop:
  lda PuzzleMap,y
  bpl :+ ; all playfield tiles are >128, or negative
  jsr CallFix
: iny
  beq :+
  cpy #128
  bne FixLoop
:

  lda DidFix
  beq :+
    inc PuzzleRedraw,x

    lda VirusCount
    bne NoVictory
      ; Can't win if the other player already won
      jsr PuzzleOtherPlayer
      lda PuzzleState,y
      cmp #PuzzleStates::VICTORY
      beq NoVictory

;      lda #PuzzleSFX::WIN
;      jsr PuzzlePlaySFX
      stx TempX
      sty TempY
      jsr FamiToneMusicStop
      ldy TempY
      ldx TempX

      lda #PuzzleStates::FAILURE
      sta PuzzleState,y


      ; Display "You win!" message
      ldy PuzzlePlayfieldBase
      lda #$14
      sta PuzzleMap+PUZZLE_HEIGHT*1,y
      lda #$15
      sta PuzzleMap+PUZZLE_HEIGHT*2,y
      lda #$16
      sta PuzzleMap+PUZZLE_HEIGHT*3,y
      lda #$17
      sta PuzzleMap+PUZZLE_HEIGHT*4,y
      lda #$18
      sta PuzzleMap+PUZZLE_HEIGHT*5,y
      lda #$19
      sta PuzzleMap+PUZZLE_HEIGHT*6,y
      lda #0
      sta PuzzleMap+PUZZLE_HEIGHT*0,y
      sta PuzzleMap+PUZZLE_HEIGHT*7,y

      lda #60
      sta PuzzleFallTimer+0
      sta PuzzleFallTimer+1

      lda #PuzzleStates::VICTORY
      sta PuzzleState,x
      inc PuzzleRedraw,x

      txa
      tay
      jsr ScorePointForPlayerY
    NoVictory:
    rts
  :

  ; .----------------------------------
  ; | Try gravity now
  ; '----------------------------------
  lda #0
  sta DidFix
  lda #PUZZLE_WIDTH-1
  sta Column
  lda #PUZZLE_HEIGHT-1
  sta Row
GravityLoop:
  jsr PuzzleGridRead
  bne :+ ; only run for blank space
  lda PuzzleMap-1,y
  beq :+ ; that have a non-blank space above
  jsr CallGravity
:
  ; Next column
  dec Column
  bpl GravityLoop
  ; Next row
  lda #PUZZLE_WIDTH-1
  sta Column
  dec Row
  ; Skip row 0
  bne GravityLoop

  lda DidFix
  beq :+
    ldy PuzzleGravitySpeed,x
    lda PuzzleGravitySpeeds,y
    sta PuzzleFallTimer,x

    inc PuzzleRedraw,x
    rts
  :

  ; Check matches again if no gravity happened
  lda #PuzzleStates::CHECK_MATCH
  sta PuzzleState,x
  rts

; .------------------------------------
; | Tile fixing
; '------------------------------------
; Call one of the fix routines
CallFix:
  sty TempY
  and #7
  tay
  lda FixTableH,y
  pha
  lda FixTableL,y
  pha
  ldy TempY
  rts

; virus, single, left, right, bottom, top, clearing, nothing
FixTableL:
  .lobytes HasVirus-1, NoFix-1, FixLeft-1, FixRight-1, FixBottom-1, FixTop-1, FixClearing-1, NoFix-1
FixTableH:
  .hibytes HasVirus-1, NoFix-1, FixLeft-1, FixRight-1, FixBottom-1, FixTop-1, FixClearing-1, NoFix-1

HasVirus:
  inc VirusCount
  rts

FixClearing:
  inc DidFix
  lda #0
  sta PuzzleMap,y
NoFix:
  rts

FixLeft:
  lda PuzzleMap+PUZZLE_HEIGHT,y
  and #7
  cmp #PuzzleTiles::RIGHT
  beq :+
    lda PuzzleMap,y
    and #<~7
    ora #PuzzleTiles::SINGLE
    sta PuzzleMap,y
    inc DidFix
  :
  rts

FixRight:
  lda PuzzleMap-PUZZLE_HEIGHT,y
  and #7
  cmp #PuzzleTiles::LEFT
  beq :+
    lda PuzzleMap,y
    and #<~7
    ora #PuzzleTiles::SINGLE
    sta PuzzleMap,y
    inc DidFix
  :
  rts

FixBottom:
  lda PuzzleMap-1,y
  and #7
  cmp #PuzzleTiles::TOP
  beq :+
    lda PuzzleMap,y
    and #<~7
    ora #PuzzleTiles::SINGLE
    sta PuzzleMap,y
    inc DidFix
  :
  rts

FixTop:
  lda PuzzleMap+1,y
  and #7
  cmp #PuzzleTiles::BOTTOM
  beq :+
    lda PuzzleMap,y
    and #<~7
    ora #PuzzleTiles::SINGLE
    sta PuzzleMap,y
    inc DidFix
  :
  rts

; .------------------------------------
; | Gravity routines
; '------------------------------------
CallGravity:
  sty TempY
  ; Pick based on the tile above (still in accumulator)
  and #7
  tay
  lda GravityTableH,y
  pha
  lda GravityTableL,y
  pha
  ldy TempY
  rts

; virus, single, left, right, bottom, top, clearing, nothing
GravityTableL:
  .lobytes NoFix-1, GravitySingle-1, GravityLeft-1, GravityRight-1, GravitySingle-1, GravitySingle-1, NoFix-1, NoFix-1
GravityTableH:
  .hibytes NoFix-1, GravitySingle-1, GravityLeft-1, GravityRight-1, GravitySingle-1, GravitySingle-1, NoFix-1, NoFix-1

GravitySingle:
  lda PuzzleMap-1,y
  sta PuzzleMap,y
  lda #0
  sta PuzzleMap-1,y
  inc DidFix
  rts
GravityLeft:
  lda PuzzleMap+PUZZLE_HEIGHT,y
  bne :+
    lda PuzzleMap-1,y
    sta PuzzleMap,y
    lda PuzzleMap-1+PUZZLE_HEIGHT,y
    sta PuzzleMap+PUZZLE_HEIGHT,y
    lda #0
    sta PuzzleMap-1,y
    sta PuzzleMap-1+PUZZLE_HEIGHT,y
    inc DidFix
  :
  rts
GravityRight:
  lda PuzzleMap-PUZZLE_HEIGHT,y
  bne :+
    lda PuzzleMap-1,y
    sta PuzzleMap,y
    lda PuzzleMap-1-PUZZLE_HEIGHT,y
    sta PuzzleMap-PUZZLE_HEIGHT,y
    lda #0
    sta PuzzleMap-1,y
    sta PuzzleMap-1-PUZZLE_HEIGHT,y
    inc DidFix
  :
  rts

.endproc

; input: X = Player number 
.proc PuzzleInit ; Init the actual playfield
; Playfield generation logic adapted from Vitamins for GBA
Column = 0
Row = 1
VirusesLeft = 2
MaxY = 3
Color = 4
Failures = 5
TileNum = 6

  lda #PuzzleStates::INIT_PILL
  sta PuzzleState,x
  inc PuzzleRedraw,x

  .if 0
  ; Player 2 copies player 1's playfield
  ; if the level is the same
  cpx #1
  bne NotPlayer2
  lda VirusLevel+0
  cmp VirusLevel+1
  bne NotPlayer2
    ldy #0
  : lda PuzzleMap,y
    sta PuzzleMap+128,y
    iny
    cpy #128
    bne :-
    lda PuzzleNextColor1+0
    sta PuzzleNextColor1+1
    lda PuzzleNextColor2+0
    sta PuzzleNextColor2+1
    rts
  NotPlayer2:
  .endif

; Init the next color
  jsr PuzzlePrescription
  lda 0
  sta PuzzleNextColor1,x
  lda 1
  sta PuzzleNextColor2,x

  lda PuzzleGimmick
  cmp #PuzzleGimmicks::DOUBLES
  bne :+
    lda PuzzleNextColor1,x
    sta PuzzleNextColor2,x
  :

  ; Right now just directly use the virus level as virus count
  lda VirusLevel,x
  sta VirusesLeft

  lda #200
  sta Failures

  jsr PuzzleRandomColor
  sta Color
  jsr CalculateTileNum

; Calculate maximum allowed height
  lda VirusesLeft
  cmp #79
  bcc :+
    ; If 176+80 = 256, which will give us zero
    ; so just hardcode the height.
    lda #12
    sta MaxY
    bne :++
  :
  lda #176
  add VirusesLeft
  ldy #20
  jsr div8
  sta MaxY
  :

; Clear playfield
  lda #0
  ldy PuzzlePlayfieldBase
: sta PuzzleMap,y
  iny
  beq :+
  cpy #128
  bne :-
:

  ; -----------------------------------

AddVirusLoop:
  ; Bail if too many failures
  lda Failures
  jeq AbortAddVirus

  jsr RandomByte
  and #7
  sta Column

: jsr RandomByte
  and #15
  cmp MaxY
  bcs :-
  ; Reverse subtraction, start from the bottom
  eor #255
  sec
  adc #PUZZLE_HEIGHT-1
  sta Row

  ; Make sure this space isn't already taken, and move to a different column if it is
  jsr PuzzleGridRead
  beq XOkay

  lda Column
  eor #4
  sta Column
  jsr PuzzleGridRead
  beq XOkay

  lda Column
  eor #2
  sta Column
  jsr PuzzleGridRead
  beq XOkay

  lda Column
  eor #1
  sta Column
  jsr PuzzleGridRead
  beq XOkay

  dec Failures
  bne AddVirusLoop
  jmp AbortAddVirus
XOkay:

  ; Y is now the index of the grid square the virus is going in

  ; Avoid three-in-a-rows
  lda Column
  cmp #2
  bcc :+
    lda TileNum
    cmp PuzzleMap-PUZZLE_HEIGHT*1,y
    bne :+
    cmp PuzzleMap-PUZZLE_HEIGHT*2,y
    bne :+
      dec Failures
      jmp AddVirusLoop
  :

  lda Column
  cmp #PUZZLE_WIDTH-2
  bcs :+
    lda TileNum
    cmp PuzzleMap+PUZZLE_HEIGHT*1,y
    bne :+
    cmp PuzzleMap+PUZZLE_HEIGHT*2,y
    bne :+
      dec Failures
      jmp AddVirusLoop
  :

  lda Row
  cmp #2
  bcc :+
    lda TileNum
    cmp PuzzleMap-1,y
    bne :+
    cmp PuzzleMap-2,y
    bne :+
      dec Failures
      jmp AddVirusLoop
  :

  lda Row
  cmp #PUZZLE_HEIGHT-2
  bcs :+
    lda TileNum
    cmp PuzzleMap+1,y
    bne :+
    cmp PuzzleMap+2,y
    bne :+
      dec Failures
      jmp AddVirusLoop
  :

  ; "Allow some three-in-a-rows (oxo) for really dense virus levels."
  lda Failures
  cmp #150
  bcc Under150
    ; Vertical
    lda Row
    cmp #1
    bcc :+
    cmp #PUZZLE_HEIGHT-1
    bcs :+
    lda TileNum
    cmp PuzzleMap-1,y
    bne :+
    cmp PuzzleMap+1,y
    bne :+
      dec Failures
      jmp AddVirusLoop
    :

    ; Horizontal
    lda Column
    cmp #1
    bcc :+
    cmp #PUZZLE_WIDTH-1
    bcs :+
    lda TileNum
    cmp PuzzleMap-PUZZLE_HEIGHT,y
    bne :+
    cmp PuzzleMap+PUZZLE_HEIGHT,y
    bne :+
      dec Failures
      jmp AddVirusLoop
    :
  Under150:

  ; Place the virus
  ; by writing to the playfield
  ; (Y still the index for the selected X and Y)
  lda TileNum
  sta PuzzleMap,y

  ; Cycle colors
  inc Color
  lda Color
  cmp #3
  bne :+
    lda #0
    sta Color
  :
  jsr CalculateTileNum

  dec VirusesLeft
  jne AddVirusLoop
AbortAddVirus:


.if 0
  ; Test thing for swap mode
  lda #0
  sta VirusesLeft
AddSingleLoop:
  jsr RandomByte
  and #7
  sta Column

: jsr RandomByte
  and #15
  cmp MaxY
  bcs :-
  ; Reverse subtraction, start from the bottom
  eor #255
  sec
  adc #PUZZLE_HEIGHT-1
  sta Row

  ; Make sure this space isn't already taken, and move to a different column if it is
  jsr PuzzleGridRead
  bne SingleNotOkay
    jsr PuzzleRandomColor
    sta Color
    jsr CalculateTileNum
    ora #PuzzleTiles::SINGLE
    sta PuzzleMap,y
  SingleNotOkay:
  dec VirusesLeft
  bne AddSingleLoop
.endif

  ; Make player 2 have the same pill sequence as player 1
  cpx #1
  bne :+
    jsr CopyP1RandomToP2
  :
  rts

CalculateTileNum:
  lda Color
  asl
  asl
  asl
  ora #$80 | PuzzleTiles::VIRUS
  ora PuzzleTileBase
  sta TileNum
  rts
.endproc

.proc ScorePointForPlayerY
  lda SomeoneWonOrLost
  bne Exit
  inc SomeoneWonOrLost

  lda PlayerWinsOnes,y
  add #1
  sta PlayerWinsOnes,y
  cmp #'0'+10
  bne :+
    lda #'0'
    sta PlayerWinsOnes,y
    lda PlayerWinsTens,y
    add #1
    sta PlayerWinsTens,y
    cmp #'0'+10
    bne :+
     lda #'9'
     sta PlayerWinsTens,y
  :
Exit:
  rts
.endproc
