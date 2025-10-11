.include "constants.s"

.section .data
    msg_txt: .asciz "Ingrese el texto a cifrar (maximo 16 caracteres): "
        lenMsgTxt = . - msg_txt
    msg_key: .asciz "Ingrese la clave (32 caracteres hex): "
        lenMsgKey = . - msg_key
    key_err_msg: .asciz "Error: Valor de clave incorrecto\n"
        lenKeyErr = . - key_err_msg
    newline: .asciz "\n"
    debug_state: .asciz "Matriz de Estado:\n"
        lenDebugState = . - debug_state
    debug_key: .asciz "Matriz de Clave:\n"
        lenDebugKey = . - debug_key
    msg_before_subbytes: .asciz "Estado ANTES de SubBytes:\n"
        lenMsgBeforeSub = . - msg_before_subbytes
    msg_after_subbytes: .asciz "Estado DESPUÉS de SubBytes:\n"
        lenMsgAfterSub = . - msg_after_subbytes
    msg_before_addroundkey: .asciz "Estado ANTES de AddRoundKey:\n"
        lenMsgBeforeAdd = . - msg_before_addroundkey
    msg_after_addroundkey: .asciz "Estado DESPUÉS de AddRoundKey:\n"
        lenMsgAfterAdd = . - msg_after_addroundkey
    msg_before_shiftrows: .asciz "Estado ANTES de ShiftRows:\n"
        lenMsgBeforeShift = . - msg_before_shiftrows
    msg_after_shiftrows: .asciz "Estado DESPUÉS de ShiftRows:\n"
        lenMsgAfterShift = . - msg_after_shiftrows
    msg_before_mixcolumns: .asciz "Estado ANTES de MixColumns:\n"
        lenMsgBeforeMix = . - msg_before_mixcolumns
    msg_after_mixcolumns: .asciz "Estado DESPUÉS de MixColumns:\n"
        lenMsgAfterMix = . - msg_after_mixcolumns
    msg_expanded_keys: .asciz "\n=== SUBCLAVES EXPANDIDAS ===\n"
        lenMsgExpKeys = . - msg_expanded_keys
    msg_round_key: .asciz "\nSubclave Ronda "
        lenMsgRoundKey = . - msg_round_key
    msg_colon: .asciz ":\n"
    msg_round: .asciz "\n=== RONDA "
        lenMsgRound = . - msg_round
    msg_round_end: .asciz " ===\n"
        lenMsgRoundEnd = . - msg_round_end

.section .bss
    .global matState
    matState: .space 16, 0
    .global key
    key: .space 16, 0
    .global criptograma
    criptograma: .space 16, 0
    buffer: .space 256, 0
    .global expandedKeys
    expandedKeys: .space 176, 0
    tempWord: .space 4, 0
    roundKey: .space 16, 0

.macro print fd, buffer, len
    mov x0, \fd
    ldr x1, =\buffer
    mov x2, \len
    mov x8, #64
    svc #0
.endm

.macro read fd, buffer, len
    mov x0, \fd
    ldr x1, =\buffer
    mov x2, \len
    mov x8, #63
    svc #0
.endm

.section .text

.type readTextInput, %function
.global readTextInput
readTextInput:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    read 0, buffer, 256
    ldr x1, =buffer
    ldr x2, =matState
    mov x3, #0
convert_text_loop:
    cmp x3, #16
    b.ge pad_remaining_bytes
    ldrb w4, [x1, x3]
    cmp w4, #10
    b.eq pad_remaining_bytes
    cmp w4, #0
    b.eq pad_remaining_bytes
    mov x7, #4
    udiv x8, x3, x7
    msub x9, x8, x7, x3
    mul x10, x9, x7
    add x10, x10, x8
    strb w4, [x2, x10]
    add x3, x3, #1
    b convert_text_loop
pad_remaining_bytes:
    cmp x3, #16
    b.ge convert_text_done
    mov x7, #4
    udiv x8, x3, x7
    msub x9, x8, x7, x3
    mul x10, x9, x7
    add x10, x10, x8
    mov w4, #0
    strb w4, [x2, x10]
    add x3, x3, #1
    b pad_remaining_bytes
convert_text_done:
    ldp x29, x30, [sp], #16
    ret
    .size readTextInput, (. - readTextInput)

.type convertHexKey, %function
.global convertHexKey
convertHexKey:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    read 0, buffer, 33
    ldr x1, =buffer
    ldr x2, =key
    mov x3, #0
    mov x11, #0
convert_hex_loop:
    cmp x3, #16
    b.ge convert_hex_done
skip_non_hex:
    ldrb w4, [x1, x11]
    cmp w4, #0
    b.eq convert_hex_done
    cmp w4, #10
    b.eq convert_hex_done
    bl is_hex_char
    cmp w0, #1
    b.eq process_hex_pair
    add x11, x11, #1
    b skip_non_hex
process_hex_pair:
    ldrb w4, [x1, x11]
    add x11, x11, #1
    bl hex_char_to_nibble
    lsl w5, w0, #4
    ldrb w4, [x1, x11]
    add x11, x11, #1
    bl hex_char_to_nibble
    orr w5, w5, w0
    strb w5, [x2, x3]
    add x3, x3, #1
    b convert_hex_loop
convert_hex_done:
    ldp x29, x30, [sp], #16
    ret
    .size convertHexKey, (. - convertHexKey)

is_hex_char:
    cmp w4, #'0'
    b.lt not_hex
    cmp w4, #'9'
    b.le is_hex
    orr w4, w4, #0x20
    cmp w4, #'a'
    b.lt not_hex
    cmp w4, #'f'
    b.le is_hex
not_hex:
    mov w0, #0
    ret
is_hex:
    mov w0, #1
    ret

hex_char_to_nibble:
    cmp w4, #'0'
    b.lt hex_error
    cmp w4, #'9'
    b.le hex_digit
    orr w4, w4, #0x20
    cmp w4, #'a'
    b.lt hex_error
    cmp w4, #'f'
    b.gt hex_error
    sub w0, w4, #'a'
    add w0, w0, #10
    ret
hex_digit:
    sub w0, w4, #'0'
    ret
hex_error:
    print 1, key_err_msg, lenKeyErr
    mov w0, #0
    ret

.type printMatrix, %function
.global printMatrix
printMatrix:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    str x0, [sp, #16]
    str x1, [sp, #24]
    str x2, [sp, #32]
    mov x0, #1
    ldr x1, [sp, #24]
    ldr x2, [sp, #32]
    mov x8, #64
    svc #0
    mov x23, #0
print_row_loop:
    cmp x23, #4
    b.ge print_matrix_done
    mov x24, #0
print_col_loop:
    cmp x24, #4
    b.ge print_row_newline
    mov x25, #4
    mul x25, x23, x25
    add x25, x25, x24
    ldr x20, [sp, #16]
    ldrb w0, [x20, x25]
    bl print_hex_byte
    add x24, x24, #1
    b print_col_loop
print_row_newline:
    print 1, newline, 1
    add x23, x23, #1
    b print_row_loop
print_matrix_done:
    print 1, newline, 1
    ldp x29, x30, [sp], #48
    ret
    .size printMatrix, (. - printMatrix)

print_hex_byte:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    and w1, w0, #0xF0
    lsr w1, w1, #4
    and w2, w0, #0x0F
    cmp w1, #10
    b.lt high_digit
    add w1, w1, #'A' - 10
    b high_done
high_digit:
    add w1, w1, #'0'
high_done:
    cmp w2, #10
    b.lt low_digit
    add w2, w2, #'A' - 10
    b low_done
low_digit:
    add w2, w2, #'0'
low_done:
    sub sp, sp, #16
    strb w1, [sp]
    strb w2, [sp, #1]
    mov w3, #' '
    strb w3, [sp, #2]
    mov x0, #1
    mov x1, sp
    mov x2, #3
    mov x8, #64
    svc #0
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret

.type subBytes, %function
.global subBytes
subBytes:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    ldr x19, =matState
    ldr x20, =Sbox
    mov x0, #0
subbytes_loop:
    cmp x0, #16
    b.ge subbytes_done
    ldrb w1, [x19, x0]
    uxtw x1, w1
    ldrb w2, [x20, x1]
    strb w2, [x19, x0]
    add x0, x0, #1
    b subbytes_loop
subbytes_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldp x29, x30, [sp], #32
    ret
    .size subBytes, (. - subBytes)

.type shiftRows, %function
.global shiftRows
shiftRows:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    str x21, [sp, #32]
    str x22, [sp, #40]
    ldr x19, =matState
    ldrb w20, [x19, #4]
    ldrb w21, [x19, #5]
    strb w21, [x19, #4]
    ldrb w21, [x19, #6]
    strb w21, [x19, #5]
    ldrb w21, [x19, #7]
    strb w21, [x19, #6]
    strb w20, [x19, #7]
    ldrb w20, [x19, #8]
    ldrb w21, [x19, #9]
    ldrb w22, [x19, #10]
    strb w22, [x19, #8]
    ldrb w22, [x19, #11]
    strb w22, [x19, #9]
    strb w20, [x19, #10]
    strb w21, [x19, #11]
    ldrb w20, [x19, #12]
    ldrb w21, [x19, #15]
    strb w21, [x19, #12]
    ldrb w21, [x19, #14]
    strb w21, [x19, #15]
    ldrb w21, [x19, #13]
    strb w21, [x19, #14]
    strb w20, [x19, #13]
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldr x21, [sp, #32]
    ldr x22, [sp, #40]
    ldp x29, x30, [sp], #48
    ret
    .size shiftRows, (. - shiftRows)

.type galois_mul2, %function
galois_mul2:
    and w1, w0, #0x80
    lsl w0, w0, #1
    and w0, w0, #0xFF
    cmp w1, #0x80
    b.ne galois_mul2_done
    mov w2, #0x1B
    eor w0, w0, w2
galois_mul2_done:
    ret
    .size galois_mul2, (. - galois_mul2)

.type galois_mul3, %function
galois_mul3:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    mov w19, w0
    bl galois_mul2
    eor w0, w0, w19
    ldr x19, [sp, #16]
    ldp x29, x30, [sp], #32
    ret
    .size galois_mul3, (. - galois_mul3)

.type mixColumns, %function
.global mixColumns
mixColumns:
    stp x29, x30, [sp, #-80]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    str x21, [sp, #32]
    str x22, [sp, #40]
    str x23, [sp, #48]
    str x24, [sp, #56]
    str x25, [sp, #64]
    str x26, [sp, #72]
    ldr x19, =matState
    mov x20, #0
mixcol_row_loop:
    cmp x20, #4
    b.ge mixcol_done
    ldrb w22, [x19, x20]
    add x0, x20, #4
    ldrb w23, [x19, x0]
    add x0, x20, #8
    ldrb w24, [x19, x0]
    add x0, x20, #12
    ldrb w25, [x19, x0]
    mov w0, w22
    bl galois_mul2
    mov w26, w0
    mov w0, w23
    bl galois_mul3
    eor w26, w26, w0
    eor w26, w26, w24
    eor w26, w26, w25
    sub sp, sp, #16
    str w26, [sp, #0]
    mov w26, w22
    mov w0, w23
    bl galois_mul2
    eor w26, w26, w0
    mov w0, w24
    bl galois_mul3
    eor w26, w26, w0
    eor w26, w26, w25
    str w26, [sp, #4]
    mov w26, w22
    eor w26, w26, w23
    mov w0, w24
    bl galois_mul2
    eor w26, w26, w0
    mov w0, w25
    bl galois_mul3
    eor w26, w26, w0
    str w26, [sp, #8]
    mov w0, w22
    bl galois_mul3
    mov w26, w0
    eor w26, w26, w23
    eor w26, w26, w24
    mov w0, w25
    bl galois_mul2
    eor w26, w26, w0
    str w26, [sp, #12]
    ldr w26, [sp, #0]
    strb w26, [x19, x20]
    add x0, x20, #4
    ldr w26, [sp, #4]
    strb w26, [x19, x0]
    add x0, x20, #8
    ldr w26, [sp, #8]
    strb w26, [x19, x0]
    add x0, x20, #12
    ldr w26, [sp, #12]
    strb w26, [x19, x0]
    add sp, sp, #16
    add x20, x20, #1
    b mixcol_row_loop
mixcol_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldr x21, [sp, #32]
    ldr x22, [sp, #40]
    ldr x23, [sp, #48]
    ldr x24, [sp, #56]
    ldr x25, [sp, #64]
    ldr x26, [sp, #72]
    ldp x29, x30, [sp], #80
    ret
    .size mixColumns, (. - mixColumns)

.type rotByte, %function
rotByte:
    ldrb w1, [x0, #0]
    ldrb w2, [x0, #1]
    ldrb w3, [x0, #2]
    ldrb w4, [x0, #3]
    strb w2, [x0, #0]
    strb w3, [x0, #1]
    strb w4, [x0, #2]
    strb w1, [x0, #3]
    ret
    .size rotByte, (. - rotByte)

.type byteSub, %function
byteSub:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    mov x19, x0
    ldr x20, =Sbox
    mov x1, #0
bytesub_loop:
    cmp x1, #4
    b.ge bytesub_done
    ldrb w2, [x19, x1]
    uxtw x2, w2
    ldrb w3, [x20, x2]
    strb w3, [x19, x1]
    add x1, x1, #1
    b bytesub_loop
bytesub_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldp x29, x30, [sp], #32
    ret
    .size byteSub, (. - byteSub)

.type xorWords, %function
xorWords:
    ldrb w2, [x0, #0]
    ldrb w3, [x1, #0]
    eor w2, w2, w3
    strb w2, [x0, #0]
    ldrb w2, [x0, #1]
    ldrb w3, [x1, #1]
    eor w2, w2, w3
    strb w2, [x0, #1]
    ldrb w2, [x0, #2]
    ldrb w3, [x1, #2]
    eor w2, w2, w3
    strb w2, [x0, #2]
    ldrb w2, [x0, #3]
    ldrb w3, [x1, #3]
    eor w2, w2, w3
    strb w2, [x0, #3]
    ret
    .size xorWords, (. - xorWords)

.type copyWord, %function
copyWord:
    ldrb w2, [x1, #0]
    strb w2, [x0, #0]
    ldrb w2, [x1, #1]
    strb w2, [x0, #1]
    ldrb w2, [x1, #2]
    strb w2, [x0, #2]
    ldrb w2, [x1, #3]
    strb w2, [x0, #3]
    ret
    .size copyWord, (. - copyWord)

.type keyExpansion, %function
.global keyExpansion
keyExpansion:
    stp x29, x30, [sp, #-64]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    str x21, [sp, #32]
    str x22, [sp, #40]
    str x23, [sp, #48]
    str x24, [sp, #56]
    ldr x19, =key
    ldr x20, =expandedKeys
    ldr x21, =Rcon
    mov x22, #0
copy_initial_key:
    cmp x22, #16
    b.ge expansion_loop_init
    ldrb w23, [x19, x22]
    strb w23, [x20, x22]
    add x22, x22, #1
    b copy_initial_key
expansion_loop_init:
    mov x22, #4
expansion_loop:
    cmp x22, #44
    b.ge expansion_done
    sub x23, x22, #1
    mov x24, #4
    mul x23, x23, x24
    add x23, x20, x23
    ldr x0, =tempWord
    mov x1, x23
    bl copyWord
    and x26, x22, #3
    cbnz x26, not_multiple_of_n
    ldr x0, =tempWord
    bl rotByte
    ldr x0, =tempWord
    bl byteSub
    lsr x25, x22, #2
    sub x25, x25, #1
    mov x24, #4
    mul x25, x25, x24
    add x25, x21, x25
    ldr x0, =tempWord
    ldrb w1, [x0, #0]
    ldrb w2, [x25, #0]
    eor w1, w1, w2
    strb w1, [x0, #0]
not_multiple_of_n:
    sub x23, x22, #4
    mov x24, #4
    mul x23, x23, x24
    add x23, x20, x23
    mov x24, #4
    mul x24, x22, x24
    add x24, x20, x24
    mov x0, x24
    mov x1, x23
    bl copyWord
    mov x0, x24
    ldr x1, =tempWord
    bl xorWords
    add x22, x22, #1
    b expansion_loop
expansion_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldr x21, [sp, #32]
    ldr x22, [sp, #40]
    ldr x23, [sp, #48]
    ldr x24, [sp, #56]
    ldp x29, x30, [sp], #64
    ret
    .size keyExpansion, (. - keyExpansion)

.type printRoundNumber, %function
printRoundNumber:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    sub sp, sp, #16
    cmp w0, #10
    b.lt single_digit
    mov w1, #'1'
    strb w1, [sp, #0]
    mov w1, #'0'
    strb w1, [sp, #1]
    mov x0, #1
    mov x1, sp
    mov x2, #2
    mov x8, #64
    svc #0
    b print_round_done
single_digit:
    add w0, w0, #'0'
    strb w0, [sp]
    mov x0, #1
    mov x1, sp
    mov x2, #1
    mov x8, #64
    svc #0
print_round_done:
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret
    .size printRoundNumber, (. - printRoundNumber)

.type printExpandedKeys, %function
.global printExpandedKeys
printExpandedKeys:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    str x21, [sp, #32]
    str x22, [sp, #40]
    print 1, msg_expanded_keys, lenMsgExpKeys
    ldr x19, =expandedKeys
    mov x20, #0
print_rounds_loop:
    cmp x20, #11
    b.ge print_rounds_done
    print 1, msg_round_key, lenMsgRoundKey
    mov w0, w20
    bl printRoundNumber
    print 1, msg_colon, 2
    mov x21, #16
    mul x21, x20, x21
    add x21, x19, x21
    // Imprimir en formato column-major (4x4)
    mov x22, #0
print_key_rows:
    cmp x22, #4
    b.ge print_key_done
    mov x23, #0
print_key_cols:
    cmp x23, #4
    b.ge print_key_row_end
    // Calcular indice column-major: columna * 4 + fila
    mov x2, #4
    mul x2, x23, x2
    add x2, x2, x22
    ldrb w0, [x21, x2]
    bl print_hex_byte
    add x23, x23, #1
    b print_key_cols
print_key_row_end:
    print 1, newline, 1
    add x22, x22, #1
    b print_key_rows
print_key_done:
    add x20, x20, #1
    b print_rounds_loop
print_rounds_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldr x21, [sp, #32]
    ldr x22, [sp, #40]
    ldp x29, x30, [sp], #48
    ret
    .size printExpandedKeys, (. - printExpandedKeys)

.type getRoundKey, %function
.global getRoundKey
getRoundKey:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    ldr x19, =expandedKeys
    mov x2, #16
    mul x2, x0, x2
    add x19, x19, x2
    mov x20, x1
    mov x2, #0
copy_round_key_loop:
    cmp x2, #16
    b.ge copy_round_key_done
    ldrb w3, [x19, x2]
    strb w3, [x20, x2]
    add x2, x2, #1
    b copy_round_key_loop
copy_round_key_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldp x29, x30, [sp], #32
    ret
    .size getRoundKey, (. - getRoundKey)

.type addRoundKeyWithRound, %function
.global addRoundKeyWithRound
addRoundKeyWithRound:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    ldr x1, =roundKey
    bl getRoundKey
    ldr x19, =matState
    ldr x20, =roundKey
    mov x0, #0
addround_loop:
    cmp x0, #16
    b.ge addround_done
    mov x1, #4
    udiv x2, x0, x1
    msub x3, x2, x1, x0
    mul x4, x3, x1
    add x4, x4, x2
    ldrb w1, [x19, x0]
    ldrb w2, [x20, x4]
    eor w3, w1, w2
    strb w3, [x19, x0]
    add x0, x0, #1
    b addround_loop
addround_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldp x29, x30, [sp], #32
    ret
    .size addRoundKeyWithRound, (. - addRoundKeyWithRound)

.type printRoundHeader, %function
printRoundHeader:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    print 1, msg_round, lenMsgRound
    sub sp, sp, #16
    cmp w0, #10
    b.lt round_single_digit
    mov w1, #'1'
    strb w1, [sp, #0]
    mov w1, #'0'
    strb w1, [sp, #1]
    mov x0, #1
    mov x1, sp
    mov x2, #2
    mov x8, #64
    svc #0
    b round_print_end
round_single_digit:
    add w0, w0, #'0'
    strb w0, [sp]
    mov x0, #1
    mov x1, sp
    mov x2, #1
    mov x8, #64
    svc #0
round_print_end:
    add sp, sp, #16
    print 1, msg_round_end, lenMsgRoundEnd
    ldp x29, x30, [sp], #16
    ret
    .size printRoundHeader, (. - printRoundHeader)

// Primera iteracion de AES-128
.type firstRoundAES, %function
.global firstRoundAES
firstRoundAES:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Ronda 0: AddRoundKey inicial
    mov w0, #0
    bl printRoundHeader
    print 1, msg_before_addroundkey, lenMsgBeforeAdd
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    mov w0, #0
    bl addRoundKeyWithRound
    print 1, msg_after_addroundkey, lenMsgAfterAdd
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    // Ronda 1: SubBytes
    mov w0, #1
    bl printRoundHeader
    print 1, msg_before_subbytes, lenMsgBeforeSub
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    bl subBytes
    print 1, msg_after_subbytes, lenMsgAfterSub
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    // ShiftRows
    print 1, msg_before_shiftrows, lenMsgBeforeShift
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    bl shiftRows
    print 1, msg_after_shiftrows, lenMsgAfterShift
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    // MixColumns
    print 1, msg_before_mixcolumns, lenMsgBeforeMix
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    bl mixColumns
    print 1, msg_after_mixcolumns, lenMsgAfterMix
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    // AddRoundKey
    print 1, msg_before_addroundkey, lenMsgBeforeAdd
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    mov w0, #1
    bl addRoundKeyWithRound
    print 1, msg_after_addroundkey, lenMsgAfterAdd
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    ldp x29, x30, [sp], #16
    ret
    .size firstRoundAES, (. - firstRoundAES)

.type _start, %function
.global _start
_start:
    print 1, msg_txt, lenMsgTxt
    bl readTextInput
    print 1, debug_state, lenDebugState
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    print 1, msg_key, lenMsgKey
    bl convertHexKey
    print 1, debug_key, lenDebugKey
    ldr x0, =key
    ldr x1, =debug_key
    mov x2, lenDebugKey
    bl printMatrix
    bl keyExpansion
    bl printExpandedKeys
    bl firstRoundAES
    mov x0, #0
    mov x8, #93
    svc #0
    .size _start, (. - _start)