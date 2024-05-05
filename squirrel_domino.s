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

.include "ns_nes.s" ; handy macros and defines

.segment "INESHDR"
  .byt "NES", $1A
  .byt 1 ; PRG in 16KB units
  .byt 1 ; CHR in 8KB units
  .byt 1 ; Horizontal arrangement
  .byt 0
.segment "VECTORS"
  .addr nmi, reset, irq

; -----------------------------------------------------------------------------
PUZZLE_WIDTH = 8
PUZZLE_HEIGHT = 16

.enum PuzzleStates
  INIT_GAME
  INIT_PILL
  FALL_PILL
  CHECK_MATCH
  GRAVITY
  VICTORY
  FAILURE
.endenum

.enum PuzzleGimmicks
  CLASSIC
  FREE_SWAP
  DOUBLES
  NO_RUSH
  UNCONNECTED

  GIMMICK_COUNT
.endenum

.enum PuzzleTiles
  VIRUS
  SINGLE
  LEFT
  RIGHT
  BOTTOM
  TOP
  CLEARING
.endenum

.enum PuzzleSFX
  ROTATE
  LAND
  CLEAR
  CLEAR2
  CLEAR3
  GARBAGE
  WIN
  FAIL
.endenum

; -----------------------------------------------------------------------------
.include "memory.s"

.code
.include "misc.s"
.include "menu.s"
.include "puzzlegame.s"
.include "puzzlelogic.s"
.include "bg_blockdata.s"
.include "backgrounds.s"
; -----------------------------------------------------------------------------

Reset:
.proc reset
  lda #0		; Turn off PPU
  sta PPUCTRL
  sta PPUMASK
  sei
  ldx #$FF	; Set up stack pointer
  txs		; Wait for PPU to stabilize

: lda PPUSTATUS
  bpl :-
: lda PPUSTATUS
  bpl :-

  lda #0
  ldx #0
: sta $000,x
  sta $100,x 
  sta $200,x 
  sta $300,x 
  sta $400,x 
  sta $500,x 
  sta $600,x 
  sta $700,x 
  inx
  bne :-
  sta OAM_DMA

  lda #0
  sta SND_CHN

  lda #0
  sta PPUMASK

  lda #VBLANK_NMI | NT_2000 | OBJ_8X8 | BG_0000 | OBJ_1000 | VRAM_RIGHT
  sta PPUCTRL

  ; Set PPU palette
  jsr ResetPalette

  jmp TitleScreen
.endproc

.proc ResetPalette
  jsr WaitVblank
  lda #$3f
  sta PPUADDR
  lda #$00
  sta PPUADDR
  ldx #0
: lda Palette,x
  sta PPUDATA
  inx
  cpx #32
  bne :-
  rts
.endproc

Palette:
  .byt $31, $0f, $00, $10
  .byt $31, $0a, $02, $05
;  .byt $30, $3a, $32, $35
  .byt $31, $0f, $22, $16
  .byt $31, $0f, $00, $10

  .byt $31, $12, $2a, $30
  .byt $31, $2d, $3d, $30
  .byt $31, $0f, $00, $10
  .byt $31, $0f, $00, $10


; Palette layout is:
;  BG 0: Text, menu and borders
;  BG 1: Background decorations
;  BG 2: Background decorations
;  BG 3: Game playfield
;
;  Sprite 0: Cursor
;  Sprite 1: Unused
;  Sprite 2: Unused
;  Sprite 3: Game playfield

.proc nmi
  inc retraces
  rti
.endproc

.proc irq
  rti
.endproc


; Music
.include "famitone/famitone2.s"
.include "famitone/novapuzzle.s"
.include "famitone/novapuzzle sfx.s"

.segment "CHR"
.incbin "puzzle.chr"
