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

  lda PuzzleVersus
  bne Versus
  ldx PuzzleBGTheme
  cpx #2
  bcc SetupPawBackground
  jmp SetupBlockBackground

Versus:
  ; Get the pointer to the compressed background data
  ldy PuzzleBGTheme
  lda VersusBackgroundPointerLo,y
  sta 0
  lda VersusBackgroundPointerHi,y
  sta 1
  jmp ParseBlockBackground
.endproc

.proc SetupPawBackground
  lda #0
  jsr ClearName

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
  ; Get the pointer to the compressed background data
  ldy PuzzleBGTheme
  lda BackgroundPointerLo-2,y
  sta Pointer+0
  lda BackgroundPointerHi-2,y
  sta Pointer+1
::ParseBlockBackground:
  ; Clear the map first
  ldx #0
  txa
: sta BlockBackgroundMap,x
  inx
  bne :-

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
  jmp ParseLoop
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

; Paws white
; Paws black
; Garden
; Trees
; Stars
; Boxes
; ?
; ?

BackgroundBGColor: .byt $30, $0f, $31, $31, $0f, $04, $31, $31

BackgroundColor11: .byt $0f, $0f, $00, $00, $00, $03, $00, $00
BackgroundColor12: .byt $00, $00, $10, $10, $10, $13, $10, $10
BackgroundColor13: .byt $10, $10, $30, $30, $30, $23, $30, $30

BackgroundColor21: .byt $3a, $0a, $1a, $1a, $1a, $1a, $1a, $1a
BackgroundColor22: .byt $3b, $01, $2a, $2a, $2a, $2a, $2a, $2a
BackgroundColor23: .byt $00, $00, $37, $37, $37, $37, $37, $37

BackgroundColor31: .byt $00, $00, $17, $17, $17, $15, $17, $17
BackgroundColor32: .byt $00, $00, $27, $27, $27, $25, $27, $27
BackgroundColor33: .byt $00, $00, $37, $37, $37, $35, $37, $37

BackgroundPointerLo:
  .lobytes GardenMap, TreesMap, StarsMap, BoxesMap, IslandsMap, BridgesMap
BackgroundPointerHi:
  .hibytes GardenMap, TreesMap, StarsMap, BoxesMap, IslandsMap, BridgesMap

VersusBackgroundPointerLo:
  .lobytes VersusPawsMap, VersusPawsMap, VersusGardenMap, VersusTreesMap, VersusStarsMap, VersusBoxesMap, VersusIslandsMap, VersusBridgesMap
VersusBackgroundPointerHi:
  .hibytes VersusPawsMap, VersusPawsMap, VersusGardenMap, VersusTreesMap, VersusStarsMap, VersusBoxesMap, VersusIslandsMap, VersusBridgesMap

.macro bg_1 type, coord_x, coord_y
  .byt type, (coord_y<<4)|coord_x
.endmacro
.macro bg_r type, coord_x, coord_y, width, height
  .byt type|128, (coord_y<<4)|coord_x, ((width-1)<<4)|(height-1)
.endmacro

; ---------------------------------------------------------

GardenMap:
  bg_r Block::Vine, 0, 6, 5, 2
  bg_1 Block::BigFlower1, 0, 5
  bg_1 Block::BigFlower1, 1, 6
  bg_1 Block::BigFlower2, 2, 5
  bg_1 Block::BigFlower4, 3, 6
  bg_1 Block::BigFlower3, 4, 5
  bg_r Block::Fence, 12, 7, 4, 1
  bg_r Block::Leaves, 11, 3, 5, 2
  bg_r Block::Leaves, 12, 2, 3, 1
  bg_r Block::Trunk, 13, 5, 1, 3
  bg_1 Block::Flower2, 14, 7

  bg_r Block::GroundM, 0, 14, 15, 1
  bg_r Block::Dirt, 0, 14, 16, 1

  bg_r Block::GroundM, 0, 8, 4, 1
  bg_r Block::GroundM, 13, 8, 3, 1
  bg_r Block::Dirt, 0, 9, 4, 1
  bg_r Block::Dirt, 13, 9, 3, 1
  bg_1 Block::GroundR, 4, 8
  bg_1 Block::GroundL, 12, 8
  bg_1 Block::DirtRight, 4, 9
  bg_1 Block::DirtLeft, 12, 9
  bg_r Block::DirtRight, 0, 10, 1, 3
  bg_1 Block::DirtInsideR, 0, 13

  bg_r Block::LineAbove, 1, 10, 4, 1
  bg_r Block::LineAbove, 12, 10, 4, 1
  bg_r Block::Leaves, 12, 11, 3, 2
  bg_1 Block::Flower4, 1, 12
  bg_1 Block::WhiteFenceL, 2, 12
  bg_1 Block::WhiteFenceM, 3, 12
  bg_1 Block::WhiteFenceR, 4, 12
  bg_1 Block::Grass, 5, 12
  bg_1 Block::Flower1, 10, 12
  bg_1 Block::Vine, 11, 12
  bg_1 Block::BigFlower1, 11, 11
  bg_1 Block::Flower3, 15, 12
  bg_r Block::GroundM, 1, 13, 15, 1
  bg_r Block::WaterTop, 6, 13, 4, 1
  bg_r Block::Water, 6, 14, 4, 1

  bg_1 Block::GroundR, 5, 13
  bg_1 Block::GroundL, 10, 13
  bg_1 Block::DirtRight, 5, 14
  bg_1 Block::DirtLeft, 10, 14

  bg_1 Block::CloudL, 1, 2
  bg_1 Block::CloudM, 2, 2
  bg_1 Block::CloudR, 3, 2
  bg_1 Block::CloudL, 2, 4
  bg_1 Block::CloudM, 3, 4
  bg_1 Block::CloudR, 4, 4
  bg_1 Block::CloudL, 5, 0
  bg_1 Block::CloudM, 6, 0
  bg_1 Block::CloudR, 7, 0
  bg_1 Block::CloudL, 11, 1
  bg_1 Block::CloudM, 12, 1
  bg_1 Block::CloudR, 13, 1
  .byt $ff

TreesMap:
  bg_r Block::Leaves, 0, 6, 5, 3
  bg_r Block::Leaves, 1, 5, 3, 1
  bg_r Block::Leaves, 11, 6, 5, 3
  bg_r Block::Leaves, 12, 5, 3, 1
  bg_r Block::GroundM, 0, 13, 16, 1
  bg_r Block::Dirt, 0, 14, 16, 1
  bg_r Block::Grass, 0, 12, 5, 1
  bg_r Block::Fence, 12, 12, 4, 1
  bg_r Block::Trunk, 2, 9, 1, 4
  bg_r Block::Trunk, 13, 9, 1, 4
  bg_r Block::Trunk, 13, 9, 1, 4
  bg_1 Block::Flower2, 1, 12
  bg_1 Block::Flower2, 11, 12
  bg_1 Block::CloudL, 1, 0
  bg_1 Block::CloudM, 2, 0
  bg_1 Block::CloudR, 3, 0
  bg_1 Block::CloudL, 0, 3
  bg_1 Block::CloudM, 1, 3
  bg_1 Block::CloudR, 2, 3
  bg_1 Block::CloudL, 4, 1
  bg_1 Block::CloudM, 5, 1
  bg_1 Block::CloudR, 6, 1
  bg_1 Block::CloudL, 9, 0
  bg_1 Block::CloudM, 10, 0
  bg_1 Block::CloudR, 11, 0
  bg_1 Block::CloudL, 11, 2
  bg_1 Block::CloudM, 12, 2
  bg_1 Block::CloudR, 13, 2
  bg_1 Block::CloudL, 13, 4
  bg_1 Block::CloudM, 14, 4
  bg_1 Block::CloudR, 15, 4
  .byt $ff

StarsMap:
  bg_r Block::GroundM, 0, 13, 16, 1
  bg_r Block::Dirt, 0, 14, 16, 1
  bg_r Block::Grass, 0, 12, 5, 1
  bg_r Block::Grass, 11, 12, 5, 1
  bg_r Block::Vine, 1, 11, 1, 2
  bg_r Block::Vine, 14, 11, 1, 2
  bg_1 Block::Vine, 3, 12
  bg_1 Block::Vine, 12, 12
  bg_1 Block::BigStar, 1, 1
  bg_1 Block::BigStar, 11, 0
  bg_1 Block::BigStar, 13, 2
  bg_1 Block::BigStar, 2, 3
  bg_1 Block::BigStar, 15, 4
  bg_1 Block::BigStar, 0, 5
  bg_1 Block::BigStar, 12, 5
  bg_1 Block::BigStar, 3, 7
  bg_1 Block::BigStar, 13, 8
  bg_1 Block::SmallStar, 5, 1
  bg_1 Block::SmallStar, 4, 4
  bg_1 Block::SmallStar, 14, 6
  bg_1 Block::SmallStar, 11, 7
  bg_1 Block::SmallStar, 1, 8
  bg_1 Block::BigFlower1, 1, 10
  bg_1 Block::BigFlower1, 3, 11
  bg_1 Block::BigFlower1, 12, 11
  bg_1 Block::BigFlower1, 14, 10
  .byt $ff

BoxesMap:
  bg_r Block::PierTop, 1, 11, 4, 1
  bg_r Block::PierMiddle, 1, 12, 4, 1
  bg_r Block::SolidBlock, 0, 13, 16, 2
  bg_r Block::Ladder, 2, 11, 1, 2
  bg_r Block::Ladder, 3, 5, 1, 4
  bg_r Block::PlatformM, 12, 11, 2, 1
  bg_r Block::BridgeMBottom, 12, 5, 2, 1
  bg_1 Block::BridgeLBottom, 11, 5
  bg_1 Block::BridgeRBottom, 14, 5
  bg_1 Block::PlatformL, 11, 11
  bg_1 Block::PlatformR, 14, 11
  bg_1 Block::WhiteFenceL, 11, 12
  bg_r Block::WhiteFenceM, 12, 12, 2, 1
  bg_1 Block::WhiteFenceR, 14, 12
  bg_r Block::Bricks, 11, 4, 4, 1
  bg_r Block::Bricks, 12, 3, 2, 1
  bg_r Block::Bricks, 12, 10, 3, 1
  bg_1 Block::Prize, 14, 9
  bg_1 Block::Prize, 4, 4
  bg_r Block::Crate, 0, 4, 3, 1
  bg_1 Block::Crate, 1, 3
  bg_1 Block::Crate, 1, 10
  bg_r Block::Crate, 3, 10, 2, 1
  bg_r Block::Crate, 11, 9, 1, 2
  bg_r Block::Crate, 12, 8, 2, 2
  bg_1 Block::Crate, 13, 7

  bg_1 Block::PlatformL, 0, 5
  bg_1 Block::PlatformM, 1, 5
  bg_1 Block::PlatformR, 2, 5
  bg_1 Block::PlatformSingle, 4, 5
  .byt $ff

IslandsMap:
  bg_r Block::WaterTop, 0, 13, 16, 1
  bg_r Block::Water,    0, 14, 16, 1
  bg_1 Block::GroundL,  5, 13
  bg_r Block::GroundM,  6, 13, 4, 1
  bg_1 Block::GroundR,  10, 13
  bg_1 Block::DirtLeft,  5, 14
  bg_r Block::Dirt, 6, 14, 4, 1
  bg_1 Block::DirtRight,  10, 14

  bg_r Block::GroundM,  1, 8, 2, 1
  bg_r Block::Dirt,  1, 9, 2, 1
  bg_r Block::LineAbove,  0, 10, 4, 1
  bg_r Block::LineAbove,  2, 5, 2, 1
  bg_r Block::LineAbove,  14, 9, 2, 1
  bg_r Block::LineAbove,  12, 11, 3, 1
  bg_1 Block::LineAbove,  12, 7
  bg_1 Block::VineTop,  2, 10
  bg_1 Block::VineTop,  4, 5
  bg_1 Block::VineTop,  11, 7
  bg_1 Block::Vine,     2, 11
  bg_1 Block::Vine,     11, 8
  bg_r Block::Vine,     4, 6, 1, 2

  bg_1 Block::GroundL,  0, 8
  bg_1 Block::DirtLeft,  0, 9
  bg_1 Block::GroundR,   3, 8
  bg_1 Block::DirtRight,  3, 9
  bg_1 Block::GroundL,  12, 10
  bg_1 Block::GroundM,  13, 10
  bg_1 Block::GroundR,  14, 10

  bg_1 Block::GroundL,  11, 5
  bg_1 Block::GroundR,  12, 5
  bg_1 Block::DirtLeft,  11, 6
  bg_1 Block::DirtRight,  12, 6

  bg_1 Block::GroundL,  14, 7
  bg_1 Block::GroundR,  15, 7
  bg_1 Block::DirtLeft,  14, 8
  bg_1 Block::DirtRight,  15, 8

  bg_1 Block::GroundL,  2, 2
  bg_1 Block::GroundM,  3, 2
  bg_1 Block::GroundR,  4, 2
  bg_r Block::DirtLeft,  2, 3, 1, 2
  bg_r Block::Dirt,      3, 3, 1, 2
  bg_r Block::DirtRight,  4, 3, 1, 2

  bg_r Block::Grass,  0, 7, 3, 1
  bg_1 Block::Grass,  11, 4
  bg_1 Block::Vine,   1, 7
  bg_1 Block::BigFlower1, 1, 6
  bg_1 Block::Spring, 14, 6
  bg_1 Block::Rock, 15, 6
  bg_1 Block::Money, 3, 1
  bg_1 Block::Money, 12, 4
  bg_1 Block::Money, 3, 7
  bg_1 Block::Money, 13, 9
  bg_1 Block::CloudL, 9, 0
  bg_1 Block::CloudM, 10, 0
  bg_1 Block::CloudR, 11, 0
  bg_1 Block::CloudL, 12, 2
  bg_1 Block::CloudM, 13, 2
  bg_1 Block::CloudR, 14, 2
  .byt $ff

BridgesMap:
  bg_r Block::WaterTop, 0, 13, 16, 1
  bg_r Block::Water,    0, 14, 16, 1
  bg_r Block::Money, 1, 8, 2, 1
  bg_r Block::Money, 13, 8, 2, 1
  bg_1 Block::Fence, 4, 10
  bg_1 Block::Fence, 11, 10
  bg_1 Block::TrunkTop, 4, 11
  bg_1 Block::TrunkTop, 11, 11
  bg_r Block::Trunk, 4, 12, 1, 3
  bg_r Block::Trunk, 11, 12, 1, 3

  bg_1 Block::DirtLeft,  6, 14
  bg_r Block::Dirt,      7, 14, 2, 1
  bg_1 Block::DirtRight, 9, 14

  bg_1 Block::GroundL,  6, 13
  bg_r Block::GroundM,  7, 13, 2, 1
  bg_1 Block::GroundR,  9, 13

  bg_r Block::BridgeMBottom, 0, 11, 3, 1
  bg_r Block::BridgeMBottom, 13, 11, 3, 1
  bg_1 Block::BridgeRBottom,  3, 11
  bg_1 Block::BridgeLBottom,  12, 11
  bg_r Block::BridgeTop, 0, 10, 4, 1
  bg_r Block::BridgeTop, 12, 10, 4, 1
  bg_1 Block::Fence, 4, 10
  bg_1 Block::Fence, 11, 10

  bg_1 Block::CloudL, 0, 1
  bg_1 Block::CloudM, 1, 1
  bg_1 Block::CloudR, 2, 1
  bg_1 Block::CloudL, 4, 0
  bg_1 Block::CloudM, 5, 0
  bg_1 Block::CloudR, 6, 0
  bg_1 Block::CloudL, 12, 0
  bg_1 Block::CloudM, 13, 0
  bg_1 Block::CloudR, 14, 0
  bg_1 Block::CloudL, 11, 2
  bg_1 Block::CloudM, 12, 2
  bg_1 Block::CloudR, 13, 2
  bg_1 Block::CloudL, 2, 4
  bg_1 Block::CloudM, 3, 4
  bg_1 Block::CloudR, 4, 4
  bg_1 Block::CloudL, 11, 2
  bg_1 Block::CloudM, 12, 2
  bg_1 Block::CloudR, 13, 2
  bg_1 Block::CloudL, 13, 5
  bg_1 Block::CloudM, 14, 5
  bg_1 Block::CloudR, 15, 5
  bg_1 Block::CloudL, 1, 6
  bg_1 Block::CloudM, 2, 6
  bg_1 Block::CloudR, 3, 6
 .byt $ff

; ---------------------------------------------------------

VersusPawsMap:
  bg_1 Block::Pawprint1, 0, 0
  bg_1 Block::Pawprint2, 2, 0
  bg_1 Block::Pawprint1, 4, 0
  bg_1 Block::Pawprint2, 6, 0
  bg_1 Block::Pawprint1, 8, 0
  bg_1 Block::Pawprint2, 10, 0
  bg_1 Block::Pawprint1, 12, 0
  bg_1 Block::Pawprint2, 14, 0

  bg_1 Block::Pawprint2, 1, 1
  bg_1 Block::Pawprint1, 3, 1
  bg_1 Block::Pawprint2, 5, 1
  bg_1 Block::Pawprint1, 7, 1
  bg_1 Block::Pawprint2, 9, 1
  bg_1 Block::Pawprint1, 11, 1
  bg_1 Block::Pawprint2, 13, 1
  bg_1 Block::Pawprint1, 15, 1

  bg_1 Block::Pawprint1, 0, 13
  bg_1 Block::Pawprint2, 2, 13
  bg_1 Block::Pawprint1, 4, 13
  bg_1 Block::Pawprint2, 6, 13
  bg_1 Block::Pawprint1, 8, 13
  bg_1 Block::Pawprint2, 10, 13
  bg_1 Block::Pawprint1, 12, 13
  bg_1 Block::Pawprint2, 14, 13

  bg_1 Block::Pawprint2, 1, 14
  bg_1 Block::Pawprint1, 3, 14
  bg_1 Block::Pawprint2, 5, 14
  bg_1 Block::Pawprint1, 7, 14
  bg_1 Block::Pawprint2, 9, 14
  bg_1 Block::Pawprint1, 11, 14
  bg_1 Block::Pawprint2, 13, 14
  bg_1 Block::Pawprint1, 15, 14
  .byt $ff

VersusGardenMap:
  bg_r Block::Leaves, 12, 12, 3, 1
  bg_1 Block::Flower4, 1, 12
  bg_1 Block::WhiteFenceL, 2, 12
  bg_1 Block::WhiteFenceM, 3, 12
  bg_1 Block::WhiteFenceR, 4, 12
  bg_1 Block::Fence, 11, 12
  bg_1 Block::Flower1, 10, 12
  bg_1 Block::Flower2, 0, 12
  bg_1 Block::Flower3, 15, 12
  bg_r Block::GroundM, 0, 13, 16, 1
  bg_r Block::Dirt, 0, 14, 16, 1
  bg_r Block::WaterTop, 6, 13, 4, 1
  bg_r Block::Water, 6, 14, 4, 1

  bg_1 Block::GroundR, 5, 13
  bg_1 Block::GroundL, 10, 13
  bg_1 Block::DirtRight, 5, 14
  bg_1 Block::DirtLeft, 10, 14

  bg_1 Block::CloudL, 5, 0
  bg_1 Block::CloudM, 6, 0
  bg_1 Block::CloudR, 7, 0
  bg_1 Block::CloudL, 11, 1
  bg_1 Block::CloudM, 12, 1
  bg_1 Block::CloudR, 13, 1
  bg_1 Block::CloudL, 0, 1
  bg_1 Block::CloudM, 1, 1
  bg_1 Block::CloudR, 2, 1
  .byt $ff

VersusTreesMap:
  bg_r Block::GroundM, 0, 13, 16, 1
  bg_r Block::Dirt, 0, 14, 16, 1
  bg_r Block::Grass, 0, 12, 5, 1
  bg_r Block::Fence, 12, 12, 4, 1
  bg_1 Block::Flower2, 1, 12
  bg_1 Block::Flower2, 11, 12
  bg_1 Block::CloudL, 1, 0
  bg_1 Block::CloudM, 2, 0
  bg_1 Block::CloudR, 3, 0
  bg_1 Block::CloudL, 4, 1
  bg_1 Block::CloudM, 5, 1
  bg_1 Block::CloudR, 6, 1
  bg_1 Block::CloudL, 9, 0
  bg_1 Block::CloudM, 10, 0
  bg_1 Block::CloudR, 11, 0

  bg_1 Block::CloudL, 13, 1
  bg_1 Block::CloudM, 14, 1
  bg_1 Block::CloudR, 15, 1

  bg_1 Block::DirtInsideL, 6, 13
  bg_r Block::Dirt, 7, 13, 2, 1
  bg_1 Block::DirtInsideR, 9, 13

  bg_1 Block::GroundL, 6, 12
  bg_1 Block::GroundR, 9, 12
  bg_r Block::GroundM, 7, 12, 2, 1
  .byt $ff

VersusStarsMap:
  bg_r Block::GroundM, 0, 13, 16, 1
  bg_r Block::Dirt, 0, 14, 16, 1
  bg_r Block::Grass, 0, 12, 5, 1
  bg_r Block::Grass, 11, 12, 5, 1
  bg_1 Block::Flower2, 1, 12
  bg_1 Block::Flower2, 2, 12
  bg_1 Block::Flower2, 12, 12
  bg_1 Block::Flower2, 14, 12
  bg_r Block::SmallStar, 7, 12, 2, 1
  bg_1 Block::BigStar, 1, 1
  bg_1 Block::BigStar, 4, 0
  bg_1 Block::BigStar, 7, 0
  bg_1 Block::BigStar, 10, 1
  bg_1 Block::BigStar, 11, 0
  bg_1 Block::SmallStar, 2, 0
  bg_1 Block::SmallStar, 5, 1
  bg_1 Block::SmallStar, 9, 0
  bg_1 Block::SmallStar, 14, 1
  bg_1 Block::SmallStar, 15, 0
  .byt $ff

VersusBoxesMap:
  bg_r Block::Bricks, 0, 13, 6, 2
  bg_r Block::Crate, 1, 12, 4, 1
  bg_r Block::Ladder, 2, 12, 1, 3
  bg_r Block::SolidBlock, 6, 13, 10, 2
  bg_r Block::PierTop, 12, 13, 2, 1
  bg_r Block::PierMiddle, 12, 14, 2, 1
  bg_1 Block::WhiteFenceL, 11, 12
  bg_r Block::WhiteFenceM, 12, 12, 2, 1
  bg_1 Block::WhiteFenceR, 14, 12

  bg_1 Block::PlatformL, 1, 1
  bg_r Block::PlatformM, 2, 1, 4, 1
  bg_1 Block::PlatformR, 6, 1
  bg_1 Block::PlatformL, 9, 1
  bg_r Block::PlatformM, 10, 1, 4, 1
  bg_1 Block::PlatformR, 14, 1

  bg_r Block::Crate, 3, 0, 4, 1
  bg_r Block::Bricks, 9, 0, 5, 1
  bg_1 Block::Prize, 5, 0
  bg_1 Block::Prize, 10, 0
  bg_1 Block::Bricks, 2, 0
  bg_r Block::Prize, 5, 12, 2, 1
  bg_1 Block::Spring, 9, 12
  bg_1 Block::Money, 1, 0
  bg_1 Block::Fence, 14, 0
  .byt $ff

VersusIslandsMap:
  bg_r Block::WaterTop, 0, 13, 16, 1
  bg_r Block::Water,    0, 14, 16, 1

  bg_r Block::GroundM,  6, 13, 4, 1
  bg_1 Block::GroundL,  5, 13
  bg_1 Block::GroundR,  10, 13

  bg_r Block::Dirt,      6, 14, 4, 1
  bg_1 Block::DirtLeft,  5, 14
  bg_1 Block::DirtRight, 10, 14

  bg_1 Block::GroundL,  1, 13
  bg_1 Block::GroundR,  2, 13
  bg_1 Block::GroundL,  13, 13
  bg_1 Block::GroundR,  14, 13
  bg_1 Block::Flower4,  1, 12
  bg_1 Block::Flower2,  2, 12
  bg_1 Block::Fence,    13, 12
  bg_1 Block::Rock,     14, 12
  bg_r Block::Grass,    6, 12, 4, 1

  bg_1 Block::CloudL, 1, 1
  bg_1 Block::CloudM, 2, 1
  bg_1 Block::CloudR, 3, 1
  bg_1 Block::CloudL, 2, 0
  bg_1 Block::CloudM, 3, 0
  bg_1 Block::CloudR, 4, 0
  bg_1 Block::CloudL, 9,  0
  bg_1 Block::CloudM, 10, 0
  bg_1 Block::CloudR, 11, 0
  bg_1 Block::CloudL, 7,  1
  bg_1 Block::CloudM, 8,  1
  bg_1 Block::CloudR, 9, 1
  bg_1 Block::CloudL, 13, 1
  bg_1 Block::CloudM, 14, 1
  bg_1 Block::CloudR, 15, 1
  .byt $ff

VersusBridgesMap:
  bg_r Block::WaterTop, 0, 14, 16, 1
  bg_r Block::Dirt,  7, 14, 2, 1
  bg_r Block::GroundM,  7, 13, 2, 1
  bg_1 Block::GroundL,  6, 13
  bg_1 Block::GroundR,  9, 13
  bg_1 Block::DirtLeft,  6, 14
  bg_1 Block::DirtRight, 9, 14

  bg_r Block::BridgeMBottom, 0, 13, 3, 1
  bg_r Block::BridgeMBottom, 13, 13, 3, 1
  bg_1 Block::BridgeRBottom, 3, 13
  bg_1 Block::BridgeRBottom, 12, 13

  bg_r Block::BridgeTop, 0, 12, 4, 1
  bg_r Block::BridgeTop, 12, 12, 4, 1
  bg_1 Block::Fence, 4, 12
  bg_1 Block::Fence, 11, 12

  bg_1 Block::CloudL, 0, 1
  bg_1 Block::CloudM, 1, 1
  bg_1 Block::CloudR, 2, 1
  bg_1 Block::CloudL, 4, 0
  bg_1 Block::CloudM, 5, 0
  bg_1 Block::CloudR, 6, 0
  bg_1 Block::CloudL, 12, 0
  bg_1 Block::CloudM, 13, 0
  bg_1 Block::CloudR, 14, 0
  bg_1 Block::CloudL, 9, 1
  bg_1 Block::CloudM, 10, 1
  bg_1 Block::CloudR, 11, 1

  bg_1 Block::TrunkTop, 4, 13
  bg_1 Block::TrunkTop, 11, 13
  bg_1 Block::Trunk, 4, 14
  bg_1 Block::Trunk, 11, 14
  .byt $ff
