#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verifica_tests.py - Comprobacion previa de los programas de tests/ SIN MARS ni Logisim.

Que hace:
  1. Ensambla cada tests/*.asm con un ensamblador minimo (solo lo que usan nuestros programas:
     instrucciones S-MIPS, addu/addiu, li, la, move, nop, blt, bge, bgt, ble, .text/.data/.word/.byte/.space).
  2. Los ejecuta con un simulador S-MIPS propio (mapa de memoria de la practica: .text en 0,
     .data en 0x2000, $gp=0x1800, $sp=0x3FFC, memoria de 16 KiB).
  3. Comprueba las reglas de [R21]: termina con syscall 10, solo servicios 10 y 11,
     <= 12 lineas de <= 48 caracteres, comentario inicial, solo instrucciones permitidas.
  4. Mide la cobertura de la tabla 3 (que programa ejecuta cada caso).

Uso:   python3 verifica_tests.py [carpeta_o_archivos.asm ...] [--hex DIR] [--guardar DIR]
        --hex DIR      escribe DIR/<nombre>.hex en formato "v3.0 hex words addressed" (opcional)
        --guardar DIR  escribe DIR/<nombre>.txt con la salida esperada

IMPORTANTE: esto NO sustituye a MARS ni a run_tests.py. Es una comprobacion independiente
para detectar errores del programa o del circuito antes de la entrega.
"""
import sys, os, re, glob

NAMES = {'zero': 0, 'at': 1, 'v0': 2, 'v1': 3, 'a0': 4, 'a1': 5, 'a2': 6, 'a3': 7,
         'k0': 26, 'k1': 27, 'gp': 28, 'sp': 29, 'fp': 30, 's8': 30, 'ra': 31}
for i in range(8):
    NAMES['t%d' % i] = 8 + i
    NAMES['s%d' % i] = 16 + i
NAMES['t8'] = 24; NAMES['t9'] = 25
M32 = 0xFFFFFFFF
DATA_BASE = 0x2000
MEMSZ = 0x4000

def reg(tok):
    tok = tok.strip()
    if not tok.startswith('$'): raise ValueError('registro invalido: ' + tok)
    n = tok[1:]
    return int(n) if n.isdigit() else NAMES[n]

def sx(v, b):
    v &= (1 << b) - 1
    return v - (1 << b) if v >> (b - 1) else v

R_FN = {'add': 0x20, 'addu': 0x21, 'sub': 0x22, 'and': 0x24, 'or': 0x25, 'slt': 0x2A}
I_OP = {'addi': 8, 'addiu': 9, 'slti': 0xA, 'andi': 0xC, 'ori': 0xD}
M_OP = {'lw': 0x23, 'sw': 0x2B, 'lb': 0x20, 'lbu': 0x24, 'sb': 0x28}
PSEUDO_BR = {'blt': ('slt', 0, 'bne'), 'bge': ('slt', 0, 'beq'),
             'bgt': ('slt', 1, 'bne'), 'ble': ('slt', 1, 'beq')}

# ----------------------------------------------------------------- ensamblador
def split_args(s):
    return [a.strip() for a in s.split(',')] if s.strip() else []

def li_size(v):
    return 1 if (-32768 <= v <= 65535) else 2

def assemble(path):
    lines = open(path, encoding='utf-8').read().splitlines()
    section = 'text'
    labels, text_items, data = {}, [], bytearray()
    pc = 0
    for ln, raw in enumerate(lines, 1):
        s = raw.split('#')[0].strip()
        while True:
            m = re.match(r'^([A-Za-z_]\w*):\s*(.*)$', s)
            if not m: break
            labels[m.group(1)] = (pc if section == 'text' else DATA_BASE + len(data))
            s = m.group(2)
        if not s: continue
        if s.startswith('.'):
            parts = s.split(None, 1); d = parts[0]; arg = parts[1] if len(parts) > 1 else ''
            if d == '.text': section = 'text'
            elif d == '.data': section = 'data'
            elif d == '.globl': pass
            elif d == '.word':
                while len(data) % 4: data.append(0)
                for t in split_args(arg): data += (int(t, 0) & M32).to_bytes(4, 'little')
            elif d == '.byte':
                for t in split_args(arg): data.append(int(t, 0) & 0xFF)
            elif d == '.space': data += bytes(int(arg, 0))
            elif d == '.align':
                while len(data) % (1 << int(arg, 0)): data.append(0)
            else: raise ValueError('%s:%d directiva no soportada %s' % (path, ln, d))
            continue
        if section != 'text': raise ValueError('%s:%d instruccion fuera de .text' % (path, ln))
        parts = s.split(None, 1); mn = parts[0].lower(); args = split_args(parts[1] if len(parts) > 1 else '')
        if mn == 'li': size = li_size(int(args[1], 0))
        elif mn == 'la' or mn in PSEUDO_BR: size = 2
        else: size = 1
        text_items.append((pc, mn, args, ln)); pc += 4 * size
    if pc > DATA_BASE: raise ValueError('.text demasiado grande')
    words = []
    def lab(t):
        t = t.strip()
        return labels[t] if t in labels else int(t, 0)
    def R(rs, rt, rd, sh, fn): return (rs << 21) | (rt << 16) | (rd << 11) | (sh << 6) | fn
    def I(op, rs, rt, imm): return (op << 26) | (rs << 21) | (rt << 16) | (imm & 0xFFFF)
    def br(op, rs, rt, target, at):
        off = (target - (at + 4)) >> 2
        if not -32768 <= off <= 32767: raise ValueError('salto fuera de rango')
        return I(op, rs, rt, off)
    for at, mn, a, ln in text_items:
        try:
            if mn in R_FN: words.append(R(reg(a[1]), reg(a[2]), reg(a[0]), 0, R_FN[mn]))
            elif mn in ('sll', 'srl'):
                sh = int(a[2], 0)
                if not 0 <= sh < 32: raise ValueError('shamt')
                words.append(R(0, reg(a[1]), reg(a[0]), sh, 0 if mn == 'sll' else 2))
            elif mn in I_OP:
                v = int(a[2], 0)
                if mn in ('andi', 'ori'):
                    if not 0 <= v <= 0xFFFF: raise ValueError('inmediato sin signo fuera de rango')
                elif not -32768 <= v <= 32767: raise ValueError('inmediato con signo fuera de rango')
                words.append(I(I_OP[mn], reg(a[1]), reg(a[0]), v))
            elif mn == 'lui':
                v = int(a[1], 0)
                if not 0 <= v <= 0xFFFF: raise ValueError('lui fuera de rango')
                words.append(I(0xF, 0, reg(a[0]), v))
            elif mn in M_OP:
                m = re.match(r'^(-?\w+)?\((\$\w+)\)$', a[1].replace(' ', ''))
                off = int(m.group(1), 0) if m.group(1) else 0
                if not -32768 <= off <= 32767: raise ValueError('desplazamiento fuera de rango')
                words.append(I(M_OP[mn], reg(m.group(2)), reg(a[0]), off))
            elif mn in ('beq', 'bne'):
                words.append(br(4 if mn == 'beq' else 5, reg(a[0]), reg(a[1]), lab(a[2]), at))
            elif mn in ('j', 'jal'):
                words.append(((2 if mn == 'j' else 3) << 26) | ((lab(a[0]) >> 2) & 0x3FFFFFF))
            elif mn == 'jr': words.append(R(reg(a[0]), 0, 0, 0, 8))
            elif mn == 'syscall': words.append(0x0000000C)
            elif mn == 'nop': words.append(0)
            elif mn == 'move': words.append(R(0, reg(a[1]), reg(a[0]), 0, 0x21))       # addu rd,$0,rs
            elif mn == 'li':
                v = int(a[1], 0); rt = reg(a[0])
                if -32768 <= v <= 32767: words.append(I(9, 0, rt, v))                  # addiu
                elif 0 <= v <= 0xFFFF: words.append(I(0xD, 0, rt, v))                  # ori
                else:
                    words.append(I(0xF, 0, 1, (v >> 16) & 0xFFFF)); words.append(I(0xD, 1, rt, v & 0xFFFF))
            elif mn == 'la':
                v = lab(a[1]); rt = reg(a[0])
                words.append(I(0xF, 0, 1, (v >> 16) & 0xFFFF)); words.append(I(0xD, 1, rt, v & 0xFFFF))
            elif mn in PSEUDO_BR:
                _, swap, bop = PSEUDO_BR[mn]
                x, y = (reg(a[1]), reg(a[0])) if swap else (reg(a[0]), reg(a[1]))
                words.append(R(x, y, 1, 0, 0x2A))                                       # slt $at,x,y
                words.append(br(5 if bop == 'bne' else 4, 1, 0, lab(a[2]), at + 4))
            else: raise ValueError('instruccion no soportada: ' + mn)
        except Exception as e:
            raise ValueError('%s:%d  %s  (%s)' % (path, ln, ' '.join([mn] + a), e))
    mem = bytearray(MEMSZ)
    for i, w in enumerate(words): mem[4 * i:4 * i + 4] = (w & M32).to_bytes(4, 'little')
    mem[DATA_BASE:DATA_BASE + len(data)] = data
    return mem, len(words), labels, pc

# ------------------------------------------------------------------ simulador
def run(mem, ev, helper=(1 << 30, 1 << 30), maxc=60000):
    mem = bytearray(mem)
    reg_ = [0] * 32; reg_[28] = 0x1800; reg_[29] = 0x3FFC
    pc = 0; out = ''; n = 0; depth = 0; sb_pos = {}
    saved_ra = False
    while n < maxc:
        i = int.from_bytes(mem[pc & 0x3FFC:(pc & 0x3FFC) + 4], 'little'); n += 1
        op = i >> 26; rs = (i >> 21) & 31; rt = (i >> 16) & 31; rd = (i >> 11) & 31
        sh = (i >> 6) & 31; fn = i & 63; imm = i & 0xFFFF; s = sx(imm, 16)
        a = reg_[rs]; b = reg_[rt]; npc = pc + 4; w = None; E = set()
        neg = lambda v: v >> 31
        if op == 0:
            if fn == 0x20:
                w = (rd, (a + b) & M32); E.add('add_neg' if neg(a) or neg(b) else 'add_pos')
                if (a >> 16) or (b >> 16): pass
            elif fn == 0x21: w = (rd, (a + b) & M32); E.add('addu')
            elif fn == 0x22:
                w = (rd, (a - b) & M32); E.add('sub_neg' if neg(a) or neg(b) else 'sub_pos')
            elif fn == 0x24:
                w = (rd, a & b)
                if (a >> 16) or (b >> 16): E.add('and_hi')
            elif fn == 0x25:
                w = (rd, a | b)
                if (a >> 16) or (b >> 16): E.add('or_hi')
            elif fn == 0x2A:
                r = int(sx(a, 32) < sx(b, 32)); w = (rd, r); E.add('slt_%d' % r)
                if r != int(a < b): E.add('slt_dif')
            elif fn == 0:
                if i != 0 or True: w = (rd, (b << sh) & M32)
                E.add('sll_0' if sh == 0 else 'sll_n')
            elif fn == 2:
                w = (rd, b >> sh); E.add('srl_0' if sh == 0 else 'srl_n')
                if sh and neg(b): E.add('srl_neg')
            elif fn == 8:
                npc = a; E.add('jr')
                if rs == 31 and depth > 0: depth -= 1
            elif fn == 0xC:
                v0 = reg_[2]
                if v0 == 10: ev.add('sys10'); return out, n, True, 'ok'
                if v0 == 11: ev.add('sys11'); out += chr(reg_[4] & 0x7F)
                else: return out, n, False, 'syscall con servicio %d (solo se permiten 10 y 11)' % v0
            else: return out, n, False, 'instruccion ilegal %08x en %04x' % (i, pc)
        elif op == 8:
            w = (rt, (a + s) & M32)
            if s < 0: E.add('addi_neg')
        elif op == 9: w = (rt, (a + s) & M32); E.add('addiu')
        elif op == 0xA:
            r = int(sx(a, 32) < s); w = (rt, r); E.add('slti_%d' % r)
            if r != int(a < (s & M32)): E.add('slti_dif')
        elif op == 0xC:
            w = (rt, a & imm)
            if imm & 0x8000: E.add('andi_b15')
        elif op == 0xD:
            w = (rt, a | imm)
            if imm & 0x8000: E.add('ori_b15')
        elif op == 0xF:
            w = (rt, imm << 16)
            if imm & 0x8000: E.add('lui_b15')
        elif op in (0x23, 0x20, 0x24, 0x2B, 0x28):
            d = ((a + s) & M32) & 0x3FFF
            if op == 0x23:
                w = (rt, int.from_bytes(mem[d & ~3:(d & ~3) + 4], 'little'))
                E.add('lw_pos' if s > 0 else 'lw_neg' if s < 0 else 'lw_0')
            elif op in (0x20, 0x24):
                byte = mem[d]; w = (rt, (sx(byte, 8) & M32) if op == 0x20 else byte)
                if byte & 0x80: E.add(('lb_pos%d' if op == 0x20 else 'lbu_pos%d') % (d & 3))
            elif op == 0x2B:
                mem[d & ~3:(d & ~3) + 4] = b.to_bytes(4, 'little')
                E.add('sw_pos' if s > 0 else 'sw_neg' if s < 0 else 'sw_0')
                if rt == 31: saved_ra = True
            else:
                mem[d] = b & 0xFF; sb_pos.setdefault(d & ~3, set()).add(d & 3)
                if len(sb_pos[d & ~3]) == 4: E.add('sb_4pos')
        elif op in (4, 5):
            take = (a == b) if op == 4 else (a != b)
            nm = 'beq' if op == 4 else 'bne'
            E.add(nm + ('_t' if take else '_n'))
            if take:
                npc = pc + 4 + (s << 2)
                if s < 0: E.add('salto_atras')
        elif op == 2: npc = ((pc + 4) & 0xF0000000) | ((i & 0x3FFFFFF) << 2); E.add('j')
        elif op == 3:
            reg_[31] = pc + 4; npc = ((pc + 4) & 0xF0000000) | ((i & 0x3FFFFFF) << 2)
            if depth >= 1 and saved_ra: E.add('jal_nohoja')
            depth += 1; E.add('jal')
        else: return out, n, False, 'instruccion ilegal %08x en %04x' % (i, pc)
        if w is not None:
            if w[0] == 0:
                if i != 0: E.add('zero_write')
            else: reg_[w[0]] = w[1]
        if not (helper[0] <= pc < helper[1]): ev |= E
        pc = npc
    return out, n, False, 'no termina antes de %d instrucciones' % maxc

def write_hex(mem, path):
    rows = []
    for r in range(0, MEMSZ // 4, 8):
        ws = [int.from_bytes(mem[4 * (r + k):4 * (r + k) + 4], 'little') for k in range(8)]
        if any(ws): rows.append('%03x: %s' % (r, ' '.join('%08x' % w for w in ws)))
    open(path, 'w', newline='').write('v3.0 hex words addressed\r\n' + '\r\n'.join(rows) + '\r\n')

# ----------------------------------------------------------------- cobertura
FILAS = [
    ('add, sub: operandos positivos',            ['add_pos', 'sub_pos']),
    ('add, sub: con un operando negativo',       ['add_neg', 'sub_neg']),
    ('and, or: unos en los 16 bits altos',       ['and_hi', 'or_hi']),
    ('slt/slti: resultado 1 y resultado 0',      ['slt_1', 'slt_0', 'slti_1', 'slti_0']),
    ('slt/slti: signo != sin signo',             ['slt_dif', 'slti_dif']),
    ('sll, srl: shamt = 0',                      ['sll_0', 'srl_0']),
    ('sll, srl: shamt != 0',                     ['sll_n', 'srl_n']),
    ('srl sobre valor negativo',                 ['srl_neg']),
    ('addi con inmediato negativo',              ['addi_neg']),
    ('addiu (li) y addu (move)',                 ['addiu', 'addu']),
    ('andi, ori con bit 15 = 1',                 ['andi_b15', 'ori_b15']),
    ('lui con bit 15 = 1',                       ['lui_b15']),
    ('lw, sw con desplazamiento positivo',       ['lw_pos', 'sw_pos']),
    ('lw, sw con desplazamiento negativo',       ['lw_neg', 'sw_neg']),
    ('lb en 2 posiciones con bit 7 = 1',         ['LB2']),
    ('lbu en 2 posiciones con bit 7 = 1',        ['LBU2']),
    ('sb en las 4 posiciones de una palabra',    ['sb_4pos']),
    ('beq, bne tomados y no tomados',            ['beq_t', 'beq_n', 'bne_t', 'bne_n']),
    ('salto hacia atras',                        ['salto_atras']),
    ('j',                                        ['j']),
    ('jal, jr con procedimiento no hoja',        ['jal_nohoja', 'jr']),
    ('syscall 11 y 10',                          ['sys11', 'sys10']),
    ('escritura en $zero',                       ['zero_write']),
]

def derivados(ev):
    ev = set(ev)
    if sum(1 for e in ev if e.startswith('lb_pos')) >= 2: ev.add('LB2')
    if sum(1 for e in ev if e.startswith('lbu_pos')) >= 2: ev.add('LBU2')
    return ev

def main():
    args = sys.argv[1:]; hexdir = savedir = None
    if '--hex' in args: k = args.index('--hex'); hexdir = args[k + 1]; del args[k:k + 2]
    if '--guardar' in args: k = args.index('--guardar'); savedir = args[k + 1]; del args[k:k + 2]
    files = []
    for a in (args or ['tests']):
        files += sorted(glob.glob(os.path.join(a, '*.asm'))) if os.path.isdir(a) else [a]
    if not files: print('No hay .asm'); return 1
    for d in (hexdir, savedir):
        if d: os.makedirs(d, exist_ok=True)
    cover, ok_all = {}, True
    for f in files:
        name = os.path.splitext(os.path.basename(f))[0]
        print('=' * 60); print(name)
        problems = []
        first = open(f, encoding='utf-8').readline().strip()
        if not first.startswith('#'): problems.append('no empieza con un comentario')
        try:
            mem, nw, labs, tend = assemble(f)
        except Exception as e:
            print('  ERROR al ensamblar:', e); ok_all = False; continue
        ev = set()
        out, n, halted, msg = run(mem, ev, helper=(labs.get('pw', 1 << 30), tend))
        if not halted: problems.append(msg)
        lines = out.split('\n')
        if lines and lines[-1] == '': lines = lines[:-1]
        if len(lines) > 12: problems.append('%d lineas (max 12)' % len(lines))
        for k, l in enumerate(lines, 1):
            if len(l.rstrip()) > 48: problems.append('linea %d con %d caracteres (max 48)' % (k, len(l.rstrip())))
        print('  instrucciones ensambladas: %d | ejecutadas: %d | termina con syscall 10: %s' % (nw, n, 'si' if halted else 'NO'))
        print('  salida (%d lineas):' % len(lines))
        for l in lines: print('    |' + l)
        if problems:
            ok_all = False
            for p in problems: print('  PROBLEMA:', p)
        else: print('  reglas [R21] (formato): OK')
        cover[name] = derivados(ev)
        if hexdir: write_hex(mem, os.path.join(hexdir, name + '.hex'))
        if savedir: open(os.path.join(savedir, name + '.txt'), 'w').write(out)
    print('=' * 60); print('COBERTURA de la tabla 3 (segun el simulador)')
    faltan = []
    for fila, evs in FILAS:
        progs = [p for p, e in cover.items() if all(x in e for x in evs)]
        if not progs: progs = [p for p, e in cover.items() if any(x in e for x in evs)]
        todos = all(any(x in e for e in cover.values()) for x in evs)
        print('  %-42s %s %s' % (fila, 'OK ' if todos else 'FALTA', ', '.join(progs)))
        if not todos: faltan.append(fila)
    print()
    if ok_all and not faltan: print('RESULTADO: todos los programas cumplen el formato y se cubren todas las filas.')
    else: print('RESULTADO: hay problemas (ver arriba).')
    return 0 if ok_all and not faltan else 1

if __name__ == '__main__':
    sys.exit(main())
