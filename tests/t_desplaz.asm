# t_desplaz.asm - pruebas propias de la CPU S-MIPS
# Cubre: sll y srl con shamt = 0 y con shamt distinto de 0, y srl
#   sobre un valor negativo (deben entrar ceros). Tambien jal/jr y
#   syscall 11/10. Salida: 3 filas de palabras en hexadecimal.
        .text
main:   lui  $s0, 0x8000
        ori  $s0, $s0, 1         # 0x80000001 (negativo)
        lui  $s1, 0x1234
        ori  $s1, $s1, 0x5678    # 0x12345678
        sll  $a0, $s0, 0         # shamt = 0
        jal  pw
        sll  $a0, $s0, 1
        jal  pw
        sll  $a0, $s0, 4
        jal  pw
        sll  $a0, $s0, 31
        jal  pw
        sll  $a0, $s1, 8
        jal  pw
        jal  pnl
        srl  $a0, $s0, 0         # shamt = 0 sobre negativo
        jal  pw
        srl  $a0, $s0, 1         # entran ceros
        jal  pw
        srl  $a0, $s0, 4
        jal  pw
        srl  $a0, $s0, 31
        jal  pw
        srl  $a0, $s1, 8
        jal  pw
        jal  pnl
        sll  $a0, $s1, 16
        jal  pw
        srl  $a0, $s1, 16
        jal  pw
        sll  $a0, $s1, 0
        jal  pw
        srl  $a0, $s1, 0
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

