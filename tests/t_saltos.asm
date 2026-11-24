# t_saltos.asm - pruebas propias de la CPU S-MIPS
# Cubre: beq y bne tomados y no tomados, saltos hacia atras (bucle
#   con bne y con beq), j, y las pseudoinstrucciones blt y bge.
#   Cada comprobacion suma un bit en una mascara que se imprime.
#   Salida: 2 filas de palabras en hexadecimal.
        .text
main:   li   $s0, 7
        li   $s1, 7
        li   $s2, 9
        li   $s3, 0
        beq  $s0, $s1, t1          # tomado
        j    n1                     # camino de fallo
t1:     addi $s3, $s3, 1           # bit 0: beq tomado
n1:     beq  $s0, $s2, n2          # no tomado
        addi $s3, $s3, 2           # bit 1: beq no tomado
n2:     bne  $s0, $s2, t3          # tomado
        j    n3
t3:     addi $s3, $s3, 4           # bit 2: bne tomado
n3:     bne  $s0, $s1, n4          # no tomado
        addi $s3, $s3, 8           # bit 3: bne no tomado
n4:     j    sigue                  # j: salta la linea siguiente
        li   $s3, 0x666             # no debe ejecutarse
sigue:  move $a0, $s3              # 0x0000000f
        jal  pw
        li   $t2, 0
        li   $t3, 5
        li   $s4, 0
lp:     addi $t2, $t2, 1
        add  $s4, $s4, $t2
        bne  $t2, $t3, lp          # salto hacia atras con bne
        move $a0, $s4              # 1+2+3+4+5 = 15
        jal  pw
        move $a0, $t2              # 5
        jal  pw
        li   $t2, 3
        li   $s5, 0
lq:     beq  $t2, $zero, fin1      # salto hacia delante
        addi $s5, $s5, 10
        addi $t2, $t2, -1
        beq  $zero, $zero, lq      # salto hacia atras con beq
fin1:   move $a0, $s5              # 30 = 0x1e
        jal  pw
        jal  pnl
        li   $t2, -3
        li   $t3, 2
        li   $s6, 0
        blt  $t2, $t3, p1          # -3 < 2 con signo: tomado
        j    p2
p1:     addi $s6, $s6, 1
p2:     bge  $t2, $t3, p3          # no tomado
        addi $s6, $s6, 2
p3:     move $a0, $s6              # 3
        jal  pw
        move $a0, $s3              # la mascara sigue en 0xf
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
