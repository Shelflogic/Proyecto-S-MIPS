# t_procs.asm - pruebas propias de la CPU S-MIPS
# Cubre: jal y jr con procedimientos no hoja que guardan $ra (y $s0)
#   en la pila y retornan bien: suma recursiva (profundidad 11) y un
#   procedimiento que llama a otro dos veces. Comprueba que la pila
#   queda equilibrada y que $s0 se conserva. Usa syscall 11 y 10.
#   Salida: una fila de palabras en hexadecimal.
        .text
main:   li   $s0, 0x1234
        li   $a0, 10
        jal  suma                  # 10+9+...+0 = 55 = 0x37
        move $a0, $v0
        jal  pw
        li   $a0, 5
        jal  dos                   # doble(5)+doble(6) = 22 = 0x16
        move $a0, $v0
        jal  pw
        move $a0, $sp             # pila equilibrada: 0x00003ffc
        jal  pw
        move $a0, $s0             # $s0 conservado: 0x00001234
        jal  pw
        jal  pnl
        li   $v0, 10
        syscall

suma:   addi $sp, $sp, -8          # suma(n) = n + suma(n-1)
        sw   $ra, 4($sp)
        sw   $a0, 0($sp)
        bne  $a0, $zero, s_rec
        move $v0, $zero
        j    s_fin
s_rec:  addi $a0, $a0, -1
        jal  suma
        lw   $a0, 0($sp)
        add  $v0, $v0, $a0
s_fin:  lw   $ra, 4($sp)
        addi $sp, $sp, 8
        jr   $ra
dos:    addi $sp, $sp, -12         # dos(a) = doble(a) + doble(a+1)
        sw   $ra, 8($sp)
        sw   $s0, 4($sp)
        sw   $a0, 0($sp)
        jal  doble
        move $s0, $v0
        lw   $a0, 0($sp)
        addi $a0, $a0, 1
        jal  doble
        add  $v0, $v0, $s0
        lw   $s0, 4($sp)
        lw   $ra, 8($sp)
        addi $sp, $sp, 12
        jr   $ra
doble:  add  $v0, $a0, $a0
        jr   $ra
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
