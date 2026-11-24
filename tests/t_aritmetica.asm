# t_aritmetica.asm - pruebas propias de la CPU S-MIPS
# Cubre: add y sub con operandos positivos y con uno negativo,
#   addi con inmediato negativo, addiu (li con constantes de
#   -32768 a 32767) y addu (move). Tambien jal/jr y syscall 11/10.
# Salida: 4 filas de palabras en hexadecimal.
        .text
main:   li   $s0, 1000          # addiu
        li   $s1, -7            # addiu con negativo
        add  $a0, $s0, $s1      # 993
        jal  pw
        sub  $a0, $s0, $s1      # 1007
        jal  pw
        sub  $a0, $s1, $s0      # -1007
        jal  pw
        add  $a0, $s1, $s1      # -14
        jal  pw
        add  $a0, $s0, $s0      # 2000
        jal  pw
        jal  pnl
        addi $a0, $s0, -1        # 999
        jal  pw
        addi $a0, $s1, -100      # -107
        jal  pw
        addi $a0, $zero, -32768  # extremo inferior
        jal  pw
        addi $a0, $s0, 500       # 1500
        jal  pw
        addi $a0, $s1, 7         # 0
        jal  pw
        jal  pnl
        li   $s2, 32767
        li   $s3, -32768
        add  $a0, $s2, $s3      # -1
        jal  pw
        sub  $a0, $s2, $s3      # 65535
        jal  pw
        move $a0, $s3            # addu
        jal  pw
        move $a0, $s2            # addu
        jal  pw
        li   $s4, 123
        li   $s5, 4567
        sub  $a0, $s4, $s5      # -4444
        jal  pw
        jal  pnl
        add  $a0, $s4, $s5      # 4690
        jal  pw
        move $s6, $s1
        add  $a0, $s6, $s0      # 993
        jal  pw
        sub  $a0, $zero, $s1    # 7
        jal  pw
        sub  $a0, $s5, $s4      # 4444
        jal  pw
        add  $a0, $zero, $zero  # 0
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

