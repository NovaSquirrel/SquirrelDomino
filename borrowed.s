; Princess Engine
; Copyright (C) 2014-2019 NovaSquirrel
;
; This program is free software: you can redistribute it and/or
; modify it under the terms of the GNU General Public License as
; published by the Free Software Foundation; either version 3 of the
; License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
; General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

.proc ReseedRandomizer
; Set some random seeds
  ldx retraces
  stx random1+0
  inx
  stx random1+1
  inx
  stx random2+0
  inx
  stx random2+1
  rts
.endproc

; clear the nametable (including attributes)
.proc ClearName
  lda #$3f ; clear tile
Custom:
  ldx #$20
  ldy #$00
  stx PPUADDR
  sty PPUADDR
AddressSet:
  ldx #64
  ldy #4
: sta PPUDATA
  inx
  bne :-
  dey
  bne :-
;Clear the attributes
  ldy #64
  lda #0
: sta PPUDATA
  dey
  bne :-
  sta PPUSCROLL
  sta PPUSCROLL
  rts
.endproc
ClearNameCustom = ClearName::Custom

; clear the second (right) nametable
.proc ClearNameRight
  lda #$3f
Custom:
  ldx #$24
  ldy #$00
  stx PPUADDR
  sty PPUADDR
  jmp ClearName::AddressSet
.endproc
ClearNameRightCustom = ClearNameRight::Custom

; sets the Y position for every sprite to an offscreen value
.proc ClearOAM
  lda #$f8
  ldy #0
  sty OamPtr
: sta OAM_YPOS,y
  iny
  iny
  iny
  iny
  bne :-
  rts
.endproc

.proc KeyRepeat
  lda keydown
  beq NoAutorepeat
  cmp keylast
  bne NoAutorepeat
  inc PlaceBlockAutorepeat
  lda PlaceBlockAutorepeat
  cmp #12
  bcc SkipNoAutorepeat

  lda retraces
  and #3
  bne :+
  lda keydown
  and #KEY_LEFT|KEY_RIGHT|KEY_UP|KEY_DOWN
  ora keynew
  sta keynew
:

  ; Keep it from going up to 255 and resetting
  dec PlaceBlockAutorepeat
  bne SkipNoAutorepeat
NoAutorepeat:
  lda #0
  sta PlaceBlockAutorepeat
SkipNoAutorepeat:

  rts
.endproc

WritePPURepeated16:
  ldx #16
; Write "A" to the PPU "X" times
.proc WritePPURepeated
: sta PPUDATA
  dex
  bne :-
  rts
.endproc

.proc BCD99
  .byt $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
  .byt $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39
  .byt $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59
  .byt $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79
  .byt $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $90, $91, $92, $93, $94, $95, $96, $97, $98, $99
.endproc

LevelMap = $600

.segment "ZEROPAGE"
  MaxNumTileUpdates  = 4
  TileUpdateA1:    .res MaxNumTileUpdates ; \ address
  TileUpdateA2:    .res MaxNumTileUpdates ; /
  TileUpdateT:     .res MaxNumTileUpdates ; new byte
  PlaceBlockAutorepeat: .res 1 ; Autorepeat timer
  TempVal:     .res 4
  TempX:       .res 1 ; for saving the X register
  TempY:       .res 1 ; for saving the Y register
  OamPtr:      .res 1
  PlayerDir:   .res 1
  TouchTemp:   .res 10
.code
