// game.S — AArch64 (ARM64) for macOS

.set GRID_W, 20
.set GRID_H, 15
.set GRID_N, (GRID_W*GRID_H)

.text
.align 2
.globl _game_init
.globl _game_reset_level
.globl _game_update
.globl _game_get_player
.globl _game_get_tile
.globl _game_get_level

// -------------------- DATA --------------------
.data
.align 3
_current_level: .word 0
_player_x:     .word 1
_player_y:     .word 1

// Levels live in a single place:
.include "src/levels.inc"

// -------------------- CODE --------------------
.text

// w0=x, w1=y  -> w0 = y*GRID_W + x
_calc_index:
    mov     w2, #GRID_W
    mul     w1, w1, w2
    add     w0, w0, w1
    ret

// ------------------------------------------------
_game_init:
    // current_level=0; player=(1,1)
    adrp    x0, _current_level@PAGE
    add     x0, x0, _current_level@PAGEOFF
    mov     w1, #0
    str     w1, [x0]

    adrp    x2, _player_x@PAGE
    add     x2, x2, _player_x@PAGEOFF
    mov     w3, #1
    str     w3, [x2]

    adrp    x4, _player_y@PAGE
    add     x4, x4, _player_y@PAGEOFF
    mov     w5, #1
    str     w5, [x4]
    ret

// ------------------------------------------------
// void game_reset_level(int level)  // sets current_level and positions player to '3'
_game_reset_level:
    // prologue
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // normalize level to [0..9]
    mov     w2, w0
    cmp     w2, #0
    bge     1f
    mov     w2, #0
1:
    cmp     w2, #10
    blt     2f
    sub     w2, w2, #10
2:
    // current_level = w2
    adrp    x0, _current_level@PAGE
    add     x0, x0, _current_level@PAGEOFF
    str     w2, [x0]

    // base = _levels_blob + level*GRID_N
    adrp    x4, _levels_blob@PAGE
    add     x4, x4, _levels_blob@PAGEOFF
    mov     w5, #GRID_N
    umaddl  x6, w2, w5, xzr
    add     x4, x4, x6              // x4 = base

    // defaults (in case no '3' exists)
    adrp    x14, _player_x@PAGE
    add     x14, x14, _player_x@PAGEOFF
    mov     w13, #1
    str     w13, [x14]
    adrp    x15, _player_y@PAGE
    add     x15, x15, _player_y@PAGEOFF
    mov     w12, #1
    str     w12, [x15]

    // find first '3' and set player
    mov     x8, #0
3:
    cmp     x8, #GRID_N
    b.ge    4f
    ldrb    w9, [x4, x8]
    cmp     w9, #3
    b.ne    5f
    // (x,y) from index
    mov     x10, x8
    mov     x11, #GRID_W
    udiv    x12, x10, x11           // y
    msub    x13, x12, x11, x10      // x
    str     w13, [x14]
    str     w12, [x15]
    b       4f
5:
    add     x8, x8, #1
    b       3b
4:
    // epilogue
    ldp     x29, x30, [sp], #16
    ret

// ------------------------------------------------
// int game_update(int dir)  // 0 up,1 right,2 down,3 left; return 1 if goal
_game_update:
    // prologue
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    cmp     w0, #0
    blt     90f
    cmp     w0, #3
    bgt     90f

    // load player
    adrp    x9, _player_x@PAGE
    add     x9, x9, _player_x@PAGEOFF
    ldr     w10, [x9]               // px

    adrp    x11, _player_y@PAGE
    add     x11, x11, _player_y@PAGEOFF
    ldr     w12, [x11]              // py

    // propose (nx,ny)
    mov     w13, w10
    mov     w14, w12
    cmp     w0, #0
    bne     1f
    subs    w14, w14, #1            // up
    b       2f
1:  cmp     w0, #1
    bne     3f
    adds    w13, w13, #1            // right
    b       2f
3:  cmp     w0, #2
    bne     4f
    adds    w14, w14, #1            // down
    b       2f
4:  cmp     w0, #3
    bne     90f
    subs    w13, w13, #1            // left

2:  // bounds
    cmp     w13, #0; blt 90f
    cmp     w14, #0; blt 90f
    mov     w1, #GRID_W; cmp w13, w1; bhs 90f
    mov     w1, #GRID_H; cmp w14, w1; bhs 90f

    // idx = y*W + x
    mov     w0, w13
    mov     w1, w14
    bl      _calc_index             // w0 = idx
    uxtw    x2, w0
    cmp     x2, #GRID_N
    bhs     90f

    // base = _levels_blob + current_level*GRID_N
    adrp    x0, _current_level@PAGE
    add     x0, x0, _current_level@PAGEOFF
    ldr     w1, [x0]                // cur level
    mov     w3, #GRID_N
    umaddl  x4, w1, w3, xzr
    adrp    x5, _levels_blob@PAGE
    add     x5, x5, _levels_blob@PAGEOFF
    add     x5, x5, x4

    // read target tile
    ldrb    w3, [x5, x2]
    cmp     w3, #1
    beq     90f                     // wall -> no move

    // commit move
    str     w13, [x9]
    str     w14, [x11]

    // goal?
    cmp     w3, #2
    cset    w0, eq                  // 1 if goal, else 0

    // epilogue
    ldp     x29, x30, [sp], #16
    ret

90:
    mov     w0, #0
    ldp     x29, x30, [sp], #16
    ret

// ------------------------------------------------
_game_get_player:
    adrp    x2, _player_x@PAGE
    add     x2, x2, _player_x@PAGEOFF
    ldr     w3, [x2]
    str     w3, [x0]

    adrp    x2, _player_y@PAGE
    add     x2, x2, _player_y@PAGEOFF
    ldr     w3, [x2]
    str     w3, [x1]
    ret

// ------------------------------------------------
// int game_get_tile(int index)
_game_get_tile:
    cmp     w0, #0
    blt     1f
    cmp     w0, #GRID_N
    bge     1f

    // base = _levels_blob + current_level*GRID_N
    adrp    x3, _current_level@PAGE
    add     x3, x3, _current_level@PAGEOFF
    ldr     w1, [x3]
    mov     w2, #GRID_N
    umaddl  x4, w1, w2, xzr
    adrp    x5, _levels_blob@PAGE
    add     x5, x5, _levels_blob@PAGEOFF
    add     x5, x5, x4

    uxtw    x2, w0
    ldrb    w0, [x5, x2]
    ret
1:
    mov     w0, #0
    ret

// ------------------------------------------------
_game_get_level:
    adrp    x0, _current_level@PAGE
    add     x0, x0, _current_level@PAGEOFF
    ldr     w0, [x0]
    ret