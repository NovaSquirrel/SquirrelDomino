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

; Read two controllers
.proc PuzzleReadJoy
  lda keydown+0
  sta keylast+0
  lda keydown+1
  sta keylast+1

  lda #$01
  sta $4016
  sta keydown+0
  sta keydown+1  ; player 2's buttons double as a ring counter
  lsr a          ; now A is 0
  sta $4016
: lda $4016
  and #%00000011  ; ignore bits other than controller
  cmp #$01        ; Set carry if and only if nonzero
  rol keydown+0   ; Carry -> bit 0; bit 7 -> Carry
  lda $4017       ; Repeat
  and #%00000011
  cmp #$01
  rol keydown+1  ; Carry -> bit 0; bit 7 -> Carry
  bcc :-

  ; Update keylast
  lda keylast+0
  eor #$FF
  and keydown+0
  sta keynew+0

  lda keylast+1
  eor #$FF
  and keydown+1
  sta keynew+1
  rts
.endproc

.proc KeyRepeat
  lda keynew,x
  sta key_new_or_repeat,x

  lda keydown,x
  beq NoAutorepeat
  cmp keylast,x
  bne NoAutorepeat
  inc KeyRepeatTimer,x
  lda KeyRepeatTimer,x
  cmp #8
  bcc SkipNoAutorepeat

  lda retraces
  and #3
  bne :+
  lda keydown
  and #KEY_LEFT|KEY_RIGHT|KEY_UP|KEY_DOWN
  ora key_new_or_repeat,x
  sta key_new_or_repeat,x
:

  ; Keep it from going up to 255 and resetting
  dec KeyRepeatTimer,x
  bne SkipNoAutorepeat
NoAutorepeat:
  lda #0
  sta KeyRepeatTimer,x
SkipNoAutorepeat:
  rts
.endproc

WaitVblank:
.proc wait_vblank
  lda retraces
  loop:
    cmp retraces
    beq loop
  rts
.endproc

; Writes a zero terminated string to the screen
; (by Ross Archer)
.proc PutStringImmediate
    DPL = $02
    DPH = $03
    pla             ; Get the low part of "return" address
                    ; (data start address)
    sta DPL
    pla 
    sta DPH         ; Get the high part of "return" address
                    ; (data start address)
                    ; Note: actually we're pointing one short
PSINB:
    ldy #1
    lda (DPL),y     ; Get the next string character
    inc DPL         ; update the pointer
    bne PSICHO      ; if not, we're pointing to next character
    inc DPH         ; account for page crossing
PSICHO:
    ora #0          ; Set flags according to contents of accumulator
                    ;    Accumulator
    beq PSIX1       ; don't print the final NULL 
    sta PPUDATA     ; write it out
    jmp PSINB       ; back around
PSIX1:
    inc DPL
    bne PSIX2
    inc DPH         ; account for page crossing
PSIX2:
    jmp (DPL)       ; return to byte following final NULL
.endproc

.proc RandomByte
  ; Based on code from https://www.nesdev.org/wiki/Random_number_generator/Linear_feedback_shift_register_(advanced)
  tya
  pha

  ; rotate the middle bytes left
  ldy random2,x ; will move to random3,x at the end
  lda random1,x
  sta random2,x
  ; compute random1,x ($C5>>1 = %1100010)
  lda random3,x ; original high byte
  lsr
  sta random1,x ; reverse: 100011
  lsr
  lsr
  lsr
  lsr
  eor random1,x
  lsr
  eor random1,x
  eor random0,x ; combine with original low byte
  sta random1,x
  ; compute random0,x ($C5 = %11000101)
  lda random3,x ; original high byte
  asl
  eor random3,x
  asl
  asl
  asl
  asl
  eor random3,x
  asl
  asl
  eor random3,x
  sty random3,x ; finish rotating byte 2 into 3
  sta random0,x

  pla
  tay
  lda random0,x
  rts
.endproc

.proc div8 ; see also mul8
num = 10   ; <-- also result
denom = 11
  stx TempX
  sta num
  sty denom
  lda #$00
  ldx #$07
  clc
: rol num
  rol
  cmp denom
  bcc :+
  sbc denom
: dex
  bpl :--
  rol num
  tay
  ldx TempX
  lda num
  rts
.endproc

.proc ReseedRandomizer
; Set some random seeds
  ldx retraces
  stx random0+0
  stx random0+1
  inx
  stx random1+0
  stx random1+1
  inx
  stx random2+0
  stx random2+1
  inx
  stx random3+0
  stx random3+1
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
