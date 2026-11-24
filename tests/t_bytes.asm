# t_bytes.asm - pruebas propias de la CPU S-MIPS
# Cubre: lb y lbu sobre bytes con el bit 7 a 1 en dos posiciones
#   distintas de la palabra (d[1:0] = 0 y 2) y en otras; sb en las
#   cuatro posiciones de una misma palabra, comprobando con lw que
#   los otros bytes no cambian (incluye sb con un registro con unos
#   en los bits altos). Salida: 4 filas en hexadecimal.
        .data
bytes:  .word 0x04F27F81        # bytes: 81 7F F2 04 (little-endian)
pal:    .word 0xAABBCCDD
        .text
main:   la   $s0, bytes
        lb   $a0, 0($s0)          # 0x81 con signo  -> ffffff81
        jal  pw
        lbu  $a0, 0($s0)          # 0x81 sin signo  -> 00000081
        jal  pw
        lb   $a0, 1($s0)          # 0x7F            -> 0000007f
        jal  pw
        lbu  $a0, 1($s0)
        jal  pw
        lb   $a0, 2($s0)          # 0xF2            -> fffffff2
        jal  pw
        jal  pnl
        lbu  $a0, 2($s0)          # 0x000000f2
        jal  pw
        lb   $a0, 3($s0)          # 0x04
        jal  pw
        lbu  $a0, 3($s0)
        jal  pw
        addi $s1, $s0, 3
        lb   $a0, -3($s1)         # desplazamiento negativo: byte 0
        jal  pw
        lw   $a0, 0($s0)          # la palabra no ha cambiado
        jal  pw
        jal  pnl
        la   $s2, pal
        lw   $a0, 0($s2)          # 0xAABBCCDD
        jal  pw
        li   $t2, 0x11
        sb   $t2, 0($s2)          # byte 0
        lw   $a0, 0($s2)          # 0xAABBCC11
        jal  pw
        li   $t2, 0x22
        sb   $t2, 1($s2)          # byte 1
        lw   $a0, 0($s2)          # 0xAABB2211
        jal  pw
        li   $t2, -102             # 0xFFFFFF9A: solo cuenta el byte bajo
        sb   $t2, 2($s2)          # byte 2
        lw   $a0, 0($s2)          # 0xAA9A2211
        jal  pw
        li   $t2, 0x44
        sb   $t2, 3($s2)          # byte 3
        lw   $a0, 0($s2)          # 0x449A2211
        jal  pw
        jal  pnl
        lbu  $a0, 2($s2)          # 0x9a
        jal  pw
        lb   $a0, 2($s2)          # 0xffffff9a
        jal  pw
        lw   $a0, 0($s0)          # la otra palabra sigue igual
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
