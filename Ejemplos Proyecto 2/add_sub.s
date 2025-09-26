.include "constants.s"
//CADENAS DE TEXTO
.section .data
    msg_txt: .asciz "Ingrese el texto a cifrar (maximo 16 caracteres): "
        lenMsgTxt = . - msg_txt

    msg_key:         .asciz "Ingrese la clave (32 caracteres hex): "
        lenMsgKey = . - msg_key

    key_err_msg:     .asciz "Error: Valor de clave incorrecto\n"
        lenKeyErr = . - key_err_msg

    newline:         .asciz "\n"
    
    debug_state:     .asciz "Matriz de Estado:\n"
        lenDebugState = . - debug_state
    
    debug_key:       .asciz "Matriz de Clave:\n"
        lenDebugKey = . - debug_key
    
    msg_before_subbytes: .asciz "Estado ANTES de SubBytes:\n"
        lenMsgBeforeSub = . - msg_before_subbytes
    
    msg_after_subbytes:  .asciz "Estado DESPUÉS de SubBytes:\n"
        lenMsgAfterSub = . - msg_after_subbytes
    
    msg_before_addroundkey: .asciz "Estado ANTES de AddRoundKey (XOR con clave):\n"
        lenMsgBeforeAdd = . - msg_before_addroundkey
    
    msg_after_addroundkey:  .asciz "Estado DESPUÉS de AddRoundKey:\n"
        lenMsgAfterAdd = . - msg_after_addroundkey
    
    msg_testing_subbytes: .asciz "=== TESTING SUBBYTES ===\n"
        lenMsgTestingSub = . - msg_testing_subbytes
    
    msg_testing_addroundkey: .asciz "=== TESTING ADDROUNDKEY ===\n"
        lenMsgTestingAdd = . - msg_testing_addroundkey
    
    msg_menu: .asciz "\n=== MENU AES ===\n1. Cifrar texto personalizado (AddRoundKey + SubBytes)\n2. Probar solo AddRoundKey\n3. Probar solo SubBytes con datos estándar\n4. Salir\nSeleccione opcion: "
        lenMsgMenu = . - msg_menu
    
    msg_invalid_option: .asciz "Opcion invalida\n"
        lenMsgInvalidOption = . - msg_invalid_option

// ===== RESERVACION DE MEMORIA =====
.section .bss
    .global matState
    matState:       .space 16, 0         // Matriz de estado del texto en claro de 128 bits

    .global key
    key:            .space 16, 0         // Matriz de llave inicial de 128 bits

    .global criptograma
    criptograma:    .space 16, 0         // Buffer para almacenar el resultado de la encriptacion

    buffer:         .space 256, 0        // Buffer utilizado para almacenar la entrada del usuario
    temp_buffer:    .space 64, 0         // Buffer temporal

// ===== MACROS =====
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

// ===== CODIGO FUENTE =====
.section .text

/* 
 * Función para leer cadena de texto y convertir a bytes ASCII
 */
.type   readTextInput, %function
.global readTextInput
readTextInput:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    // Leer entrada del usuario
    read 0, buffer, 256
    
    // Convertir caracteres a bytes ASCII y almacenar en matriz
    ldr x1, =buffer           // Puntero al buffer de entrada
    ldr x2, =matState         // Puntero a matriz de estado
    mov x3, #0                // Contador de bytes procesados
    
convert_text_loop:
    cmp x3, #16
    b.ge pad_remaining_bytes
    
    ldrb w4, [x1, x3]         // Cargar carácter
    cmp w4, #10               // Verificar si es newline
    b.eq pad_remaining_bytes
    cmp w4, #0                // Verificar si es null terminator
    b.eq pad_remaining_bytes
    
    // Almacenar carácter como byte ASCII en column-major order
    // Calcular índice: (index % 4) + (index / 4) * 4
    mov x7, #4
    udiv x8, x3, x7           // columna = index / 4
    msub x9, x8, x7, x3       // fila = index % 4
    mul x10, x9, x7           // offset = fila * 4
    add x10, x10, x8          // offset final = fila * 4 + columna
    
    strb w4, [x2, x10]        // Almacenar byte ASCII
    add x3, x3, #1
    b convert_text_loop
    
pad_remaining_bytes:
    // Rellenar bytes restantes con ceros
    cmp x3, #16
    b.ge convert_text_done
    
    mov x7, #4
    udiv x8, x3, x7           // columna = index / 4
    msub x9, x8, x7, x3       // fila = index % 4
    mul x10, x9, x7           // offset = fila * 4
    add x10, x10, x8          // offset final
    
    mov w4, #0                // Padding con ceros
    strb w4, [x2, x10]
    add x3, x3, #1
    b pad_remaining_bytes
    
convert_text_done:
    ldp x29, x30, [sp], #16
    ret
    .size readTextInput, (. - readTextInput)

/*
 * Función para convertir clave hexadecimal
 */
.type   convertHexKey, %function
.global convertHexKey
convertHexKey:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    // Leer clave hexadecimal
    read 0, buffer, 33
    
    ldr x1, =buffer           // Puntero al buffer
    ldr x2, =key              // Puntero a matriz de clave
    mov x3, #0                // Contador de bytes
    mov x11, #0               // Índice del buffer
    
convert_hex_loop:
    cmp x3, #16
    b.ge convert_hex_done
    
    // Saltar espacios y caracteres no válidos hasta encontrar hex
skip_non_hex:
    ldrb w4, [x1, x11]
    cmp w4, #0
    b.eq convert_hex_done
    cmp w4, #10               // newline
    b.eq convert_hex_done
    
    // Verificar si es carácter hex válido
    bl is_hex_char
    cmp w0, #1
    b.eq process_hex_pair
    
    add x11, x11, #1
    b skip_non_hex
    
process_hex_pair:
    // Procesar par de caracteres hex
    ldrb w4, [x1, x11]       // Primer nibble
    add x11, x11, #1
    bl hex_char_to_nibble
    lsl w5, w0, #4
    
    ldrb w4, [x1, x11]       // Segundo nibble
    add x11, x11, #1
    bl hex_char_to_nibble
    orr w5, w5, w0
    
    // Almacenar en column-major order
    mov x7, #4
    udiv x8, x3, x7           // columna = index / 4
    msub x9, x8, x7, x3       // fila = index % 4
    mul x10, x9, x7           // offset = fila * 4
    add x10, x10, x8          // offset final
    
    strb w5, [x2, x10]
    add x3, x3, #1
    b convert_hex_loop
    
convert_hex_done:
    ldp x29, x30, [sp], #16
    ret
    .size convertHexKey, (. - convertHexKey)

/*
 * Función auxiliar: verificar si es carácter hex
 */
is_hex_char:
    cmp w4, #'0'
    b.lt not_hex
    cmp w4, #'9'
    b.le is_hex
    
    orr w4, w4, #0x20         // Convertir a minúscula
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

/*
 * Función auxiliar: convertir carácter hex a nibble
 */
hex_char_to_nibble:
    cmp w4, #'0'
    b.lt hex_error
    cmp w4, #'9'
    b.le hex_digit
    
    orr w4, w4, #0x20         // Convertir a minúscula
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

/*
 * Función para imprimir matriz en formato debug
 */
.type   printMatrix, %function
.global printMatrix
printMatrix:
    stp x29, x30, [sp, #-48]!
    mov x29, sp
    
    // Guardar parámetros
    str x0, [sp, #16]         // matriz
    str x1, [sp, #24]         // mensaje
    str x2, [sp, #32]         // longitud mensaje
    
    // Imprimir mensaje
    mov x0, #1
    ldr x1, [sp, #24]
    ldr x2, [sp, #32]
    mov x8, #64
    svc #0
    
    // Imprimir matriz 4x4
    mov x23, #0               // contador de filas
    
print_row_loop:
    cmp x23, #4
    b.ge print_matrix_done
    
    mov x24, #0               // contador de columnas
    
print_col_loop:
    cmp x24, #4
    b.ge print_row_newline
    
    // Calcular índice column-major: fila*4 + columna
    mov x25, #4
    mul x25, x23, x25
    add x25, x25, x24
    
    // Cargar y mostrar byte
    ldr x20, [sp, #16]        // Recuperar puntero a matriz
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

/*
 * Función para imprimir byte en hexadecimal
 */
print_hex_byte:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Separar nibbles
    and w1, w0, #0xF0
    lsr w1, w1, #4
    and w2, w0, #0x0F
    
    // Convertir nibble alto
    cmp w1, #10
    b.lt high_digit
    add w1, w1, #'A' - 10
    b high_done
high_digit:
    add w1, w1, #'0'
high_done:
    
    // Convertir nibble bajo
    cmp w2, #10
    b.lt low_digit
    add w2, w2, #'A' - 10
    b low_done
low_digit:
    add w2, w2, #'0'
low_done:
    
    // Imprimir
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

/*
 * IMPLEMENTACIÓN DE ADDROUNDKEY - OPERACIÓN AES
 * Realiza XOR entre la matriz de estado y la clave
 * estado[i] = estado[i] XOR clave[i] para i = 0 a 15
 */
.type   addRoundKey, %function
.global addRoundKey
addRoundKey:
    // Prólogo de la función
    stp x29, x30, [sp, #-32]!    // Guardar frame pointer y link register
    mov x29, sp                   // Establecer nuevo frame pointer
    
    // Guardar registros que vamos a usar
    str x19, [sp, #16]           // Guardar x19
    str x20, [sp, #24]           // Guardar x20
    
    // Cargar direcciones base
    ldr x19, =matState           // x19 = puntero a matriz de estado
    ldr x20, =key                // x20 = puntero a clave
    
    mov x0, #0                   // x0 = contador de bytes (0-15)
    
addroundkey_loop:
    // Verificar si hemos procesado los 16 bytes
    cmp x0, #16
    b.ge addroundkey_done
    
    // Cargar byte actual del estado y de la clave
    ldrb w1, [x19, x0]          // w1 = matState[x0]
    ldrb w2, [x20, x0]          // w2 = key[x0]
    
    // Realizar operación XOR
    eor w3, w1, w2              // w3 = matState[x0] XOR key[x0]
    
    // Almacenar el resultado de vuelta en la matriz de estado
    strb w3, [x19, x0]          // matState[x0] = matState[x0] XOR key[x0]
    
    // Incrementar contador y continuar
    add x0, x0, #1
    b addroundkey_loop
    
addroundkey_done:
    // Restaurar registros
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    
    // Epílogo de la función
    ldp x29, x30, [sp], #32
    ret
    .size addRoundKey, (. - addRoundKey)

/*
 * Función de prueba para AddRoundKey
 * Muestra el estado antes y después del XOR con la clave
 */
.type   testAddRoundKey, %function
.global testAddRoundKey
testAddRoundKey:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Mensaje antes de AddRoundKey
    print 1, msg_before_addroundkey, lenMsgBeforeAdd
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    // Aplicar AddRoundKey
    bl addRoundKey
    
    // Mensaje después de AddRoundKey
    print 1, msg_after_addroundkey, lenMsgAfterAdd
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    ldp x29, x30, [sp], #16
    ret
    .size testAddRoundKey, (. - testAddRoundKey)

.type   subBytes, %function
.global subBytes
subBytes:
    // Prólogo de la función
    stp x29, x30, [sp, #-32]!    // Guardar frame pointer y link register
    mov x29, sp                   // Establecer nuevo frame pointer
    
    // Guardar registros que vamos a usar
    str x19, [sp, #16]           // Guardar x19
    str x20, [sp, #24]           // Guardar x20
    
    // Cargar direcciones base
    ldr x19, =matState           // x19 = puntero a matriz de estado
    ldr x20, =Sbox               // x20 = puntero a S-box
    
    mov x0, #0                   // x0 = contador de bytes (0-15)
    
subbytes_loop:
    // Verificar si hemos procesado los 16 bytes
    cmp x0, #16
    b.ge subbytes_done
    
    // Cargar byte actual de la matriz de estado
    ldrb w1, [x19, x0]          // w1 = matState[x0]
    
    // Extender w1 a 64 bits para usar como índice
    uxtw x1, w1                 // x1 = (uint64_t)w1
    
    // Usar el byte como índice en la S-box
    // La S-box es una tabla de 256 bytes (0x00 a 0xFF)
    ldrb w2, [x20, x1]          // w2 = Sbox[matState[x0]]
    
    // Almacenar el byte transformado de vuelta en la matriz
    strb w2, [x19, x0]          // matState[x0] = Sbox[matState[x0]]
    
    // Incrementar contador y continuar
    add x0, x0, #1
    b subbytes_loop
    
subbytes_done:
    // Restaurar registros
    ldr x19, [sp, #16]
    ldr x20, [sp, #24]
    
    // Epílogo de la función
    ldp x29, x30, [sp], #32
    ret
    .size subBytes, (. - subBytes)

/*
 * Función de prueba para SubBytes
 * Muestra el estado antes y después de la transformación
 */
.type   testSubBytes, %function
.global testSubBytes
testSubBytes:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Mensaje antes de SubBytes
    print 1, msg_before_subbytes, lenMsgBeforeSub
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    // Aplicar SubBytes
    bl subBytes
    
    // Mensaje después de SubBytes
    print 1, msg_after_subbytes, lenMsgAfterSub
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    ldp x29, x30, [sp], #16
    ret
    .size testSubBytes, (. - testSubBytes)

/*
 * Función auxiliar para inicializar matriz de prueba
 * Inicializa matState con valores conocidos del estándar AES
 */
.type   initTestMatrix, %function
.global initTestMatrix
initTestMatrix:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Valores de prueba del estándar AES
    // Estado inicial conocido para verificar SubBytes
    
    ldr x0, =matState
    
    // Fila 0 (column-major: posiciones 0, 4, 8, 12)
    mov w1, #0x19
    strb w1, [x0, #0]    // [0,0]
    mov w1, #0x3d
    strb w1, [x0, #4]    // [0,1]
    mov w1, #0xe3
    strb w1, [x0, #8]    // [0,2]
    mov w1, #0xbe
    strb w1, [x0, #12]   // [0,3]
    
    // Fila 1 (column-major: posiciones 1, 5, 9, 13)
    mov w1, #0xa0
    strb w1, [x0, #1]    // [1,0]
    mov w1, #0xf4
    strb w1, [x0, #5]    // [1,1]
    mov w1, #0xe2
    strb w1, [x0, #9]    // [1,2]
    mov w1, #0x2b
    strb w1, [x0, #13]   // [1,3]
    
    // Fila 2 (column-major: posiciones 2, 6, 10, 14)
    mov w1, #0x9a
    strb w1, [x0, #2]    // [2,0]
    mov w1, #0xc6
    strb w1, [x0, #6]    // [2,1]
    mov w1, #0x8d
    strb w1, [x0, #10]   // [2,2]
    mov w1, #0x2a
    strb w1, [x0, #14]   // [2,3]
    
    // Fila 3 (column-major: posiciones 3, 7, 11, 15)
    mov w1, #0xe9
    strb w1, [x0, #3]    // [3,0]
    mov w1, #0xf8
    strb w1, [x0, #7]    // [3,1]
    mov w1, #0x48
    strb w1, [x0, #11]   // [3,2]
    mov w1, #0x08
    strb w1, [x0, #15]   // [3,3]
    
    ldp x29, x30, [sp], #16
    ret
/*
 * Función auxiliar para inicializar clave de prueba
 * Inicializa key con la clave estándar AES de prueba
 */
.type   initTestKey, %function
.global initTestKey
initTestKey:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Clave de prueba estándar AES: 2b7e151628aed2a6abf7158809cf4f3c
    
    ldr x0, =key
    
    // Fila 0 (column-major: posiciones 0, 4, 8, 12)
    mov w1, #0x2b
    strb w1, [x0, #0]    // [0,0]
    mov w1, #0x28
    strb w1, [x0, #4]    // [0,1]
    mov w1, #0xab
    strb w1, [x0, #8]    // [0,2]
    mov w1, #0x09
    strb w1, [x0, #12]   // [0,3]
    
    // Fila 1 (column-major: posiciones 1, 5, 9, 13)
    mov w1, #0x7e
    strb w1, [x0, #1]    // [1,0]
    mov w1, #0xae
    strb w1, [x0, #5]    // [1,1]
    mov w1, #0xf7
    strb w1, [x0, #9]    // [1,2]
    mov w1, #0xcf
    strb w1, [x0, #13]   // [1,3]
    
    // Fila 2 (column-major: posiciones 2, 6, 10, 14)
    mov w1, #0x15
    strb w1, [x0, #2]    // [2,0]
    mov w1, #0xd2
    strb w1, [x0, #6]    // [2,1]
    mov w1, #0x15
    strb w1, [x0, #10]   // [2,2]
    mov w1, #0x4f
    strb w1, [x0, #14]   // [2,3]
    
    // Fila 3 (column-major: posiciones 3, 7, 11, 15)
    mov w1, #0x16
    strb w1, [x0, #3]    // [3,0]
    mov w1, #0xa6
    strb w1, [x0, #7]    // [3,1]
    mov w1, #0x88
    strb w1, [x0, #11]   // [3,2]
    mov w1, #0x3c
    strb w1, [x0, #15]   // [3,3]
    
    ldp x29, x30, [sp], #16
    ret
    .size initTestKey, (. - initTestKey)

/*
 * Función para leer opción del menú
 */
.type   readMenuOption, %function
.global readMenuOption
readMenuOption:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    // Leer una línea
    read 0, buffer, 10
    
    // Obtener primer carácter
    ldr x1, =buffer
    ldrb w0, [x1]
    
    // Convertir de ASCII a número
    sub w0, w0, #'0'
    
    ldp x29, x30, [sp], #16
    ret
    .size readMenuOption, (. - readMenuOption)

/*
 * Función de encriptación actualizada con SubBytes
 */
.type   encript, %function
.global encript
encript:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    // Aplicar SubBytes como primer paso
    bl subBytes
    
    // TODO: Aquí se agregarían los otros pasos de AES:
    // - ShiftRows
    // - MixColumns  
    // - AddRoundKey
    // Por ahora solo aplicamos SubBytes
    
    // Copiar resultado al criptograma
    ldr x0, =matState
    ldr x1, =criptograma
    mov x2, #16
copy_loop:
    cbz x2, copy_done
    ldrb w3, [x0], #1
    strb w3, [x1], #1
    sub x2, x2, #1
    b copy_loop
copy_done:

    ldp x29, x30, [sp], #16
    ret
    .size encript, (. - encript)

/*
 * Función principal con menú interactivo
 */
.type   _start, %function
.global _start
_start:
    
main_menu:
    // Mostrar menú
    print 1, msg_menu, lenMsgMenu
    
    // Leer opción
    bl readMenuOption
    
    // Verificar opción seleccionada
    cmp w0, #1
    b.eq option_custom_text
    cmp w0, #2
    b.eq option_test_addroundkey
    cmp w0, #3
    b.eq option_test_subbytes
    cmp w0, #4
    b.eq option_exit
    
    // Opción inválida
    print 1, msg_invalid_option, lenMsgInvalidOption
    b main_menu
    
option_custom_text:
    // Opción 1: Proceso completo AddRoundKey + SubBytes
    
    // Leer texto
    print 1, msg_txt, lenMsgTxt
    bl readTextInput
    
    // Mostrar estado inicial del texto
    print 1, debug_state, lenDebugState
    ldr x0, =matState
    ldr x1, =debug_state
    mov x2, lenDebugState
    bl printMatrix
    
    // Leer clave
    print 1, msg_key, lenMsgKey
    bl convertHexKey
    
    // Mostrar clave
    print 1, debug_key, lenDebugKey
    ldr x0, =key
    ldr x1, =debug_key
    mov x2, lenDebugKey
    bl printMatrix
    
    // PASO 1: AddRoundKey (XOR inicial)
    bl testAddRoundKey
    
    // PASO 2: SubBytes (sustitución)
    bl testSubBytes
    
    b main_menu
    
option_test_addroundkey:
    // Opción 2: Probar solo AddRoundKey
    print 1, msg_testing_addroundkey, lenMsgTestingAdd
    bl initTestMatrix
    bl initTestKey
    
    // Mostrar clave de prueba
    print 1, debug_key, lenDebugKey
    ldr x0, =key
    ldr x1, =debug_key
    mov x2, lenDebugKey
    bl printMatrix
    
    bl testAddRoundKey
    
    b main_menu

option_test_subbytes:
    // Opción 3: Probar solo SubBytes con datos estándar
    print 1, msg_testing_subbytes, lenMsgTestingSub
    bl initTestMatrix
    bl testSubBytes
    
    b main_menu
    
option_exit:
    // Opción 3: Salir
    mov x0, #0
    mov x8, #93
    svc #0
    
    .size _start, (. - _start)