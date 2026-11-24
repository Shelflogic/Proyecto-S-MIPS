# t_logica.asm - pruebas propias de la CPU S-MIPS
# Cubre: and y or con operandos con unos en los 16 bits altos,
#   andi y ori con inmediato con el bit 15 a 1 (extension con
#   ceros), lui con inmediato con el bit 15 a 1. Tambien jal/jr
#   y syscall 11/10. Salida: 3 filas de palabras en hexadecimal.
        .text
main:   lui  $s0, 0xF0F0
        ori  $s0, $s0, 0xF0F0    # 0xF0F0F0F0
        lui  $s1, 0xFF00
        ori  $s1, $s1, 0xFF00    # 0xFF00FF00
        lui  $s2, 0xFFFF
        ori  $s2, $s2, 0x00FF    # 0xFFFF00FF
        and  $a0, $s0, $s1
        jal  pw
        or   $a0, $s0, $s1
        jal  pw
        and  $a0, $s0, $s2
        jal  pw
        or   $a0, $s0, $s2
        jal  pw
        and  $a0, $s1, $zero
        jal  pw
        jal  pnl
        andi $a0, $s0, 0x8FF0    # bit 15 a 1: se extiende con ceros
        jal  pw
        andi $a0, $s1, 0x8000
        jal  pw
        andi $a0, $s0, 0xFFFF
        jal  pw
        ori  $a0, $zero, 0x8001
        jal  pw
        ori  $a0, $s0, 0x8001
        jal  pw
        jal  pnl
        lui  $a0, 0x8001          # bit 15 a 1
        jal  pw
        lui  $a0, 0xFFFF
        jal  pw
        lui  $a0, 0x1234
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

