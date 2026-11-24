# t_memoria.asm - pruebas propias de la CPU S-MIPS
# Cubre: lw y sw con desplazamiento positivo, negativo y cero, y lw
#   de datos iniciales de .data (la = lui+ori). Comprueba que un sw
#   con desplazamiento negativo cae en la palabra correcta.
#   Salida: 3 filas de palabras en hexadecimal.
        .data
buf:    .space 32
dato:   .word 0x11223344, -5, 0x7FFFFFFF
        .text
main:   la   $s0, buf
        addi $s0, $s0, 16         # base en la mitad del buffer
        li   $s1, 100
        li   $s2, -200
        sw   $s1, 0($s0)          # buf+16
        sw   $s2, 4($s0)          # desplazamiento positivo: buf+20
        sw   $s1, -4($s0)         # desplazamiento negativo: buf+12
        sw   $s2, -16($s0)        # desplazamiento negativo: buf+0
        lw   $a0, 0($s0)          # 100
        jal  pw
        lw   $a0, 4($s0)          # -200
        jal  pw
        lw   $a0, -4($s0)         # 100
        jal  pw
        lw   $a0, -16($s0)        # -200
        jal  pw
        lw   $a0, -8($s0)         # buf+8 sin escribir: 0
        jal  pw
        jal  pnl
        la   $s3, buf
        lw   $a0, 12($s3)         # mismo dato que -4($s0)
        jal  pw
        lw   $a0, 0($s3)          # mismo dato que -16($s0)
        jal  pw
        lw   $a0, 20($s3)         # mismo dato que 4($s0)
        jal  pw
        lw   $a0, 16($s3)         # mismo dato que 0($s0)
        jal  pw
        jal  pnl
        la   $s4, dato
        lw   $a0, 0($s4)          # 0x11223344
        jal  pw
        lw   $a0, 4($s4)          # -5
        jal  pw
        lw   $a0, 8($s4)          # 0x7FFFFFFF
        jal  pw
        addi $s4, $s4, 8
        lw   $a0, -8($s4)         # 0x11223344 con desplazamiento negativo
        jal  pw
        lw   $a0, -4($s4)         # -5
        jal  pw
        jal  pnl
        li   $v0, 10
        syscall

# ---------- subrutinas de impresion (usan $t0,$t1,$t8,$t9,$a0,$v0) ----------
pw:     move $t8, $a0           # imprime $a0 como 8 digitos hex + espacio
        li   $t9, 8
pw1:    srl  $t0, $t8, 28       # digito mas significativo
        slti $t1, $t0, 10
        bne  $t1, $zero, pw2
        addi $t0, $t0, 87       # 10..15 -> a..f
        j    pw3
pw2:    addi $t0, $t0, 48       # 0..9 -> 0..9
pw3:    move $a0, $t0
        li   $v0, 11
        syscall
        sll  $t8, $t8, 4
        addi $t9, $t9, -1
        bne  $t9, $zero, pw1
        li   $a0, 32
        li   $v0, 11
        syscall
        jr   $ra
pnl:    li   $a0, 10            # salto de linea
        li   $v0, 11
        syscall
        jr   $ra
