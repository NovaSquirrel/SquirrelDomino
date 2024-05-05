; Squirrel Domino
; Implementation of expired U.S. Patent 5265888
;
; Copyright 2024 NovaSquirrel
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
.include "bg_blockenum.s"

BlockBackgroundMap = $700

.proc PuzzleAddBackground
  lda keydown
  and #KEY_SELECT
  beq :+
    rts
  :

  ldx PuzzleBGTheme
  cpx #2
  bcc SetupPawBackground
  jmp SetupBlockBackground
.endproc

BackgroundBGColor: .byt $30, $0f, $31, $31

BackgroundColor11: .byt $0f, $0f, $00, $00
BackgroundColor12: .byt $00, $00, $10, $10
BackgroundColor13: .byt $10, $10, $30, $30

BackgroundColor21: .byt $3a, $0a, $1a, $1a
BackgroundColor22: .byt $3b, $01, $2a, $2a
BackgroundColor23: .byt $00, $00, $37, $37

BackgroundColor31: .byt $00, $00, $17, $17
BackgroundColor32: .byt $00, $00, $27, $27
BackgroundColor33: .byt $00, $00, $37, $37

.proc SetupPawBackground
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR

  jsr AllFour
  jsr AllFour
  jsr AllFour
  jsr AllFour
  jsr AllFour
  jsr AllFour
  jsr AllFour
  jsr Part1
  jsr PartEmpty
  jsr Part1
  jsr Part2
  jsr PartEmpty
  jsr Part2

  ; Attribute table
  lda #$23
  sta PPUADDR
  lda #$c0
  sta PPUADDR

  ldx #8
  lda #%01010101
: sta PPUDATA
  sta PPUDATA
  bit PPUDATA
  bit PPUDATA
  bit PPUDATA
  bit PPUDATA
  sta PPUDATA
  sta PPUDATA
  dex
  bne :-

  rts

AllFour:
  jsr Part1
  jsr PartEmpty
  jsr Part1

  jsr Part2
  jsr PartEmpty
  jsr Part2

  jsr Part3
  jsr PartEmpty
  jsr Part3

  jsr Part4
  jsr PartEmpty
  jmp Part4

Part1:
  jsr :+
: lda #$b8
  sta PPUDATA
  lda #$b9
  sta PPUDATA
  lda PPUDATA
  lda PPUDATA
  rts
Part2:
  jsr :+
: lda #$ba
  sta PPUDATA
  lda #$bb
  sta PPUDATA
  lda PPUDATA
  lda PPUDATA
  rts
Part3:
  jsr :+
: lda PPUDATA
  lda PPUDATA
  lda #$bc
  sta PPUDATA
  lda #$bd
  sta PPUDATA
  rts
Part4:
  jsr :+
: lda PPUDATA
  lda PPUDATA
  lda #$be
  sta PPUDATA
  lda #$bf
  sta PPUDATA
  rts
PartEmpty:
  ldx #16
: lda PPUDATA
  dex
  bne :-
  rts
.endproc

.proc SetupBlockBackground
Pointer = 0
Type = 2
Width = 3
Height = 4
LeftInRow = 5
  ; Clear the map first
  ldx #0
: sta BlockBackgroundMap,x
  inx
  bne :-

  ; Get the pointer to the compressed background data
  ldy PuzzleBGTheme
  lda BackgroundPointerLo-2,y
  sta Pointer+0
  lda BackgroundPointerHi-2,y
  sta Pointer+1

  ; Parse the compressed background data
  ldy #0
ParseLoop:
  lda (Pointer),y ; Get type
  iny
  cmp #255
  beq Exit
  cmp #128
  bcs WithRepeat
  pha

  lda (Pointer),y ; Get location
  iny
  tax
  pla
  sta BlockBackgroundMap,x
  jmp ParseLoop

WithRepeat:
  and #%01111111
  sta Type
  lda (Pointer),y ; Get location
  iny
  tax
  lda (Pointer),y ; Get width and height
  iny
  pha
  and #$0f
  sta Height
  pla
  lsr
  lsr
  lsr
  lsr
  sta Width

RectFill:
  lda Width
  sta LeftInRow
  lda Type
@Row:
  sta BlockBackgroundMap,x
  inx
  dec LeftInRow
  bpl @Row
  txa
  clc
  sbc Width ; Will leave carry set
  adc #16-1 ; -1 for carry being set
  tax
  dec Height
  bpl RectFill
Exit:
.endproc
; Fall through
.proc RenderBlockBackground
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR

  tax
LevelLoop:
  ; Draw the top half of the blocks on the current row
  lda #16
  sta 0
TopRowLoop:
  ldy BlockBackgroundMap,x
  lda BlockTopLeft,y
  sta PPUDATA
  lda BlockTopRight,y
  sta PPUDATA
  inx
  dec 0
  bne TopRowLoop

  txa
  sub #16
  tax

  ; Draw the bottom half of the blocks on the current row
  lda #16
  sta 0
BottomRowLoop:
  ldy BlockBackgroundMap,x
  lda BlockBottomLeft,y
  sta PPUDATA
  lda BlockBottomRight,y
  sta PPUDATA
  inx
  dec 0
  bne BottomRowLoop

  cpx #256-16
  bne LevelLoop

  ; Write attribute table
  ldx #0

AttributeBuildNewRow:
  lda #8
  sta 0
AttributeBuildLoop:
  ldy BlockBackgroundMap+0,x
  lda BlockPalette,y
  and #%00000011
  sta 1
  ldy BlockBackgroundMap+1,x
  lda BlockPalette,y
  and #%00001100
  ora 1
  sta 1
  ldy BlockBackgroundMap+16,x
  lda BlockPalette,y
  and #%00110000
  ora 1
  sta 1
  ldy BlockBackgroundMap+17,x
  lda BlockPalette,y
  and #%11000000
  ora 1
  sta PPUDATA
  inx
  inx

  dec 0
  bne AttributeBuildLoop
  txa
  add #16 ; Skip ahead a row of tiles because this loop will go through two rows at a time
  tax
  cpx #0
  bne AttributeBuildNewRow

  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  rts
.endproc

BackgroundPointerLo:
  .lobytes GardenMap, TreesMap
BackgroundPointerHi:
  .hibytes GardenMap, TreesMap

GardenMap:
  .byt 1, 0
  .byt 1, 1
  .byt 1, 2
  .byt 1, 3
  .byt 1, 4
  .byt 2|128, 5|16, $33
  .byt $ff
TreesMap:
  .byt 1, 5
  .byt 1, 6
  .byt 1, 7
  .byt 1, 8
  .byt 1, 9
  .byt $ff
