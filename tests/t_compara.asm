# t_compara.asm - pruebas propias de la CPU S-MIPS
# Cubre: slt y slti con resultado 1 y con resultado 0, y casos con
#   un operando negativo donde la comparacion con signo y sin signo
#   difieren (-1 contra 1); escritura en $zero (addi, ori, lui, add)
#   comprobando que sigue valiendo 0. Salida: 3 filas en hexadecimal.
        .text
main:   li   $s0, 1
        li   $s1, -1
        li   $s2, 5
        slt  $a0, $s1, $s0        # -1 < 1  -> 1 (sin signo daria 0)
        jal  pw
        slt  $a0, $s0, $s1        # 1 < -1  -> 0 (sin signo daria 1)
        jal  pw
        slt  $a0, $s2, $s2        # 5 < 5   -> 0
        jal  pw
        slt  $a0, $s0, $s2        # 1 < 5   -> 1
        jal  pw
        slt  $a0, $s2, $s0        # 5 < 1   -> 0
        jal  pw
        jal  pnl
        slti $a0, $s1, 1           # -1 < 1  -> 1
        jal  pw
        slti $a0, $s0, -1          # 1 < -1  -> 0 (sin signo daria 1)
        jal  pw
        slti $a0, $s2, 6           # 5 < 6   -> 1
        jal  pw
        slti $a0, $s2, 5           # 5 < 5   -> 0
        jal  pw
        slti $a0, $s1, 0           # -1 < 0  -> 1
        jal  pw
        jal  pnl
        addi $zero, $zero, 5       # escrituras en $zero: no deben tener efecto
        move $a0, $zero
        jal  pw
        ori  $zero, $s2, 0xFFFF
        lui  $zero, 0x1234
        add  $zero, $s2, $s2
        add  $a0, $zero, $zero
        jal  pw
        add  $a0, $zero, $s2      # 0 + 5
        jal  pw
        slt  $a0, $zero, $s0      # 0 < 1 -> 1
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

