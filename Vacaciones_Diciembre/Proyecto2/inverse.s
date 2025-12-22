.include "constants.s"

.section .data
    msg_last_key: .asciz "Ingrese la última clave (ronda 10): "
        lenMsgLastKey = . - msg_last_key
    key_err_msg: .asciz "Error: Valor de clave incorrecto\n"
        lenKeyErr = . - key_err_msg
    newline: .asciz "\n"
    msg_inverse_title: .asciz " EXPANSIÓN INVERSA DE CLAVES"
        lenMsgInvTitle = . - msg_inverse_title
    msg_round_key: .asciz "\nClave Ronda "
        lenMsgRoundKey = . - msg_round_key
    msg_colon: .asciz ":\n"
    msg_original_key: .asciz "CLAVE ORIGINAL (Ronda 0) "
        lenMsgOriginal = . - msg_original_key

.section .bss
    lastKey: .space 16, 0          // Última clave (ronda 10)
    expandedKeys: .space 176, 0    // Todas las subclaves (11 claves de 16 bytes)
    buffer: .space 256, 0
    tempWord: .space 4, 0

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

// Función para convertir clave hexadecimal
.type convertHexKey, %function
.global convertHexKey
convertHexKey:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    read 0, buffer, 33
    ldr x1, =buffer
    ldr x2, =lastKey
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

.type print_hex_byte, %function
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
    .size print_hex_byte, (. - print_hex_byte)

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
    b print_done
single_digit:
    add w0, w0, #'0'
    strb w0, [sp]
    mov x0, #1
    mov x1, sp
    mov x2, #1
    mov x8, #64
    svc #0
print_done:
    add sp, sp, #16
    ldp x29, x30, [sp], #16
    ret
    .size printRoundNumber, (. - printRoundNumber)

// Función para imprimir una clave (formato 4x4)
.type printKey, %function
printKey:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    mov x19, x0
    mov x20, #0
print_row_loop:
    cmp x20, #4
    b.ge print_key_done
    mov x21, #0
print_col_loop:
    cmp x21, #4
    b.ge print_row_end
    mov x2, #4
    mul x2, x21, x2
    add x2, x2, x20
    ldrb w0, [x19, x2]
    bl print_hex_byte
    add x21, x21, #1
    b print_col_loop
print_row_end:
    print 1, newline, 1
    add x20, x20, #1
    b print_row_loop
print_key_done:
    print 1, newline, 1
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldp x29, x30, [sp], #32
    ret
    .size printKey, (. - printKey)

// RotWord: rotación hacia la izquierda
.type rotWord, %function
rotWord:
    ldrb w1, [x0, #0]
    ldrb w2, [x0, #1]
    ldrb w3, [x0, #2]
    ldrb w4, [x0, #3]
    strb w2, [x0, #0]
    strb w3, [x0, #1]
    strb w4, [x0, #2]
    strb w1, [x0, #3]
    ret
    .size rotWord, (. - rotWord)

// SubWord: aplicar S-box a cada byte
.type subWord, %function
subWord:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    mov x19, x0
    ldr x20, =Sbox
    mov x1, #0
subword_loop:
    cmp x1, #4
    b.ge subword_done
    ldrb w2, [x19, x1]
    uxtw x2, w2
    ldrb w3, [x20, x2]
    strb w3, [x19, x1]
    add x1, x1, #1
    b subword_loop
subword_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldp x29, x30, [sp], #32
    ret
    .size subWord, (. - subWord)

// Función principal: expansión inversa de claves
// El proceso inverso es:
// Para cada palabra i desde 43 hasta 4:
//   Si i mod Nk == 0:
//     W[i-Nk] = W[i] XOR SubWord(RotWord(W[i-1])) XOR Rcon[i/Nk - 1]
//   Sino:
//     W[i-Nk] = W[i] XOR W[i-1]
.type inverseKeyExpansion, %function
.global inverseKeyExpansion
inverseKeyExpansion:
    stp x29, x30, [sp, #-96]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    str x21, [sp, #32]
    str x22, [sp, #40]
    str x23, [sp, #48]
    str x24, [sp, #56]
    str x25, [sp, #64]
    str x26, [sp, #72]
    str x27, [sp, #80]
    str x28, [sp, #88]
    
    ldr x19, =lastKey        // Puntero a última clave
    ldr x20, =expandedKeys   // Puntero a claves expandidas
    ldr x21, =Rcon           // Puntero a Rcon
    
    // Copiar la última clave (ronda 10) a expandedKeys[160-175]
    mov x22, #0
copy_last_key:
    cmp x22, #16
    b.ge inverse_loop_init
    ldrb w23, [x19, x22]
    add x24, x22, #160       // Offset para ronda 10 (palabra 40-43)
    strb w23, [x20, x24]
    add x22, x22, #1
    b copy_last_key

inverse_loop_init:
    mov x22, #43             // Empezar desde la palabra 43

inverse_loop:
    cmp x22, #3
    b.le inverse_done
    
    // Dirección de W[i] actual
    mov x24, #4
    mul x23, x22, x24
    add x23, x20, x23        // x23 = dirección de W[i]
    
    // Verificar si i es múltiplo de 4
    and x26, x22, #3
    cbnz x26, not_multiple_inv
    
    // i es múltiplo de 4 (Nk): aplicar transformación compleja
    // W[i-4] = W[i] XOR SubWord(RotWord(W[i-1])) XOR Rcon[i/4 - 1]
    
    // Obtener W[i-1]
    sub x24, x22, #1
    mov x25, #4
    mul x24, x24, x25
    add x24, x20, x24        // x24 = dirección de W[i-1]
    
    // Copiar W[i-1] a tempWord
    ldr x27, =tempWord
    ldrb w0, [x24, #0]
    strb w0, [x27, #0]
    ldrb w0, [x24, #1]
    strb w0, [x27, #1]
    ldrb w0, [x24, #2]
    strb w0, [x27, #2]
    ldrb w0, [x24, #3]
    strb w0, [x27, #3]
    
    // Aplicar RotWord
    mov x0, x27
    bl rotWord
    
    // Aplicar SubWord
    mov x0, x27
    bl subWord
    
    // XOR con Rcon[i/4 - 1]
    lsr x25, x22, #2         // i / 4
    sub x25, x25, #1         // (i/4) - 1
    mov x24, #4
    mul x25, x25, x24
    add x25, x21, x25        // x25 = dirección de Rcon[i/4 - 1]
    
    ldrb w0, [x27, #0]
    ldrb w1, [x25, #0]
    eor w0, w0, w1
    strb w0, [x27, #0]
    
    // Ahora tempWord = SubWord(RotWord(W[i-1])) XOR Rcon
    // W[i-4] = W[i] XOR tempWord
    sub x24, x22, #4
    mov x25, #4
    mul x24, x24, x25
    add x24, x20, x24        // x24 = dirección de W[i-4]
    
    // W[i-4] = W[i] XOR tempWord
    ldrb w0, [x23, #0]
    ldrb w1, [x27, #0]
    eor w0, w0, w1
    strb w0, [x24, #0]
    
    ldrb w0, [x23, #1]
    ldrb w1, [x27, #1]
    eor w0, w0, w1
    strb w0, [x24, #1]
    
    ldrb w0, [x23, #2]
    ldrb w1, [x27, #2]
    eor w0, w0, w1
    strb w0, [x24, #2]
    
    ldrb w0, [x23, #3]
    ldrb w1, [x27, #3]
    eor w0, w0, w1
    strb w0, [x24, #3]
    
    b continue_inverse

not_multiple_inv:
    // i NO es múltiplo de 4: W[i-4] = W[i] XOR W[i-1]
    sub x24, x22, #4
    mov x25, #4
    mul x24, x24, x25
    add x24, x20, x24        // x24 = dirección de W[i-4]
    
    sub x25, x22, #1
    mov x26, #4
    mul x25, x25, x26
    add x25, x20, x25        // x25 = dirección de W[i-1]
    
    // W[i-4] = W[i] XOR W[i-1]
    ldrb w0, [x23, #0]
    ldrb w1, [x25, #0]
    eor w0, w0, w1
    strb w0, [x24, #0]
    
    ldrb w0, [x23, #1]
    ldrb w1, [x25, #1]
    eor w0, w0, w1
    strb w0, [x24, #1]
    
    ldrb w0, [x23, #2]
    ldrb w1, [x25, #2]
    eor w0, w0, w1
    strb w0, [x24, #2]
    
    ldrb w0, [x23, #3]
    ldrb w1, [x25, #3]
    eor w0, w0, w1
    strb w0, [x24, #3]

continue_inverse:
    sub x22, x22, #1
    b inverse_loop

inverse_done:
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldr x21, [sp, #32]
    ldr x22, [sp, #40]
    ldr x23, [sp, #48]
    ldr x24, [sp, #56]
    ldr x25, [sp, #64]
    ldr x26, [sp, #72]
    ldr x27, [sp, #80]
    ldr x28, [sp, #88]
    ldp x29, x30, [sp], #96
    ret
    .size inverseKeyExpansion, (. - inverseKeyExpansion)

// Función para imprimir todas las claves expandidas
.type printAllKeys, %function
printAllKeys:
    stp x29, x30, [sp, #-32]!
    mov x29, sp
    str x19, [sp, #16]
    str x20, [sp, #24]
    
    print 1, msg_inverse_title, lenMsgInvTitle
    
    ldr x19, =expandedKeys
    mov x20, #10
    
print_keys_loop:
    cmp x20, #0
    b.lt print_original
    
    print 1, msg_round_key, lenMsgRoundKey
    mov w0, w20
    bl printRoundNumber
    print 1, msg_colon, 2
    
    mov x21, #16
    mul x21, x20, x21
    add x0, x19, x21
    bl printKey
    
    sub x20, x20, #1
    b print_keys_loop

print_original:
    print 1, msg_original_key, lenMsgOriginal
    mov x0, x19
    bl printKey
    
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    ldp x29, x30, [sp], #32
    ret
    .size printAllKeys, (. - printAllKeys)

.type _start, %function
.global _start
_start:
    print 1, msg_last_key, lenMsgLastKey
    bl convertHexKey
    
    bl inverseKeyExpansion
    
    bl printAllKeys
    
    mov x0, #0
    mov x8, #93
    svc #0
    .size _start, (. - _start)