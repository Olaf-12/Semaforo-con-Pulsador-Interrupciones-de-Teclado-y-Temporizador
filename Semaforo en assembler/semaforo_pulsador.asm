.data
msgVerde:     .asciiz "Semaforo en verde, esperando pulsador\n"
msgPulsado:   .asciiz "Pulsador activado: en 20 segundos, el semaforo cambiara a amarillo\n"
msgAmarillo:  .asciiz "Semaforo en amarillo, en 10 segundos, semaforo en rojo\n"
msgRojo:      .asciiz "Semaforo en rojo, en 30 segundos, semaforo en verde\n"

pulsador_flag: .word 0     # bandera puesta a 1 por la ISR al detectar 's'

# Direcciones MMIO del simulador de teclado/pantalla de MARS
# (.eqv es la directiva correcta en MARS para constantes; "=" no es
#  un elemento de lenguaje valido para el ensamblador de MARS)
.eqv RECV_CTRL  0xffff0000    # bit0 = Ready, bit1 = Interrupt Enable
.eqv RECV_DATA  0xffff0004    # byte bajo = caracter recibido
.eqv TRANS_CTRL 0xffff0008
.eqv TRANS_DATA 0xffff000c

#####################################################################
# RUTINA DE SERVICIO DE INTERRUPCION (ISR)
#####################################################################
        .ktext 0x80000180
        .set noat
excepcion_handler:
    # ---- Guardar contexto (solo los registros que usa esta ISR) ----
    subu $sp, $sp, 24
    sw   $at, 0($sp)
    sw   $v0, 4($sp)
    sw   $t0, 8($sp)
    sw   $t1, 12($sp)
    sw   $t2, 16($sp)
    sw   $k0, 20($sp)

    mfc0 $t0, $13              # Cause
    andi $t1, $t0, 0x7C        # ExcCode (bits 2-6)
    bnez $t1, fin_excepcion    # si no es ExcCode 0 (interrupcion), no la tratamos aqui

    # ExcCode == 0 -> es una interrupcion de hardware. En el nucleo de MARS
    # (mars.simulator.Exceptions, que es el que gobierna esta herramienta
    # "Keyboard and Display MMIO Simulator"), el bit 8 de Cause identifica
    # al teclado y el bit 9 a la pantalla.
    li   $t1, 0x00000100
    and  $t2, $t0, $t1
    beqz $t2, fin_excepcion    # no es interrupcion de teclado -> ignorar

    # Confirmar que el dispositivo esta realmente listo (bit0 de control)
    lw   $t1, RECV_CTRL
    andi $t1, $t1, 0x1
    beqz $t1, fin_excepcion

    lw   $t0, RECV_DATA
    andi $t0, $t0, 0xff        # caracter recibido

    li   $t1, 's'
    bne  $t0, $t1, fin_excepcion

    li   $t1, 1
    sw   $t1, pulsador_flag    # avisar al programa principal

fin_excepcion:
    # ---- Restaurar contexto ----
    lw   $at, 0($sp)
    lw   $v0, 4($sp)
    lw   $t0, 8($sp)
    lw   $t1, 12($sp)
    lw   $t2, 16($sp)
    lw   $k0, 20($sp)
    addu $sp, $sp, 24

    mfc0 $k0, $14              # EPC
    mtc0 $k0, $14              # (sin incrementar: es una interrupcion,
                               #  no una excepcion sincrona; se retorna
                               #  a la misma instruccion interrumpida)
    eret
        .set at

#####################################################################
# PROGRAMA PRINCIPAL
#####################################################################
        .text
        .globl main
main:
    # ---- Habilitar interrupcion a nivel de dispositivo (teclado) ----
    li   $t0, RECV_CTRL
    li   $t1, 2                # bit1 = Interrupt Enable
    sw   $t1, 0($t0)

    # ---- Habilitar interrupciones a nivel de procesador (Status) ----
    mfc0 $t0, $12
    ori  $t0, $t0, 0x0001      # IE = 1 (interrupciones globales activas)
    ori  $t0, $t0, 0xFF00      # habilita todas las mascaras IM0-IM7
    mtc0 $t0, $12

bucle_semaforo:
    # ================= ESTADO VERDE =================
    la   $a0, msgVerde
    li   $v0, 4
    syscall

    sw   $zero, pulsador_flag  # limpiar bandera antes de esperar

espera_pulsador:
    lw   $t0, pulsador_flag
    beqz $t0, espera_pulsador  # el procesador queda "a la espera";
                                # es la ISR quien pone la bandera en 1

    # ================= PULSADOR ACTIVADO =================
    la   $a0, msgPulsado
    li   $v0, 4
    syscall

    li   $a0, 20000            # 20000 ms = 20 s
    jal  delay_ms

    # ================= ESTADO AMARILLO =================
    la   $a0, msgAmarillo
    li   $v0, 4
    syscall

    li   $a0, 10000            # 10 s
    jal  delay_ms

    # ================= ESTADO ROJO =================
    la   $a0, msgRojo
    li   $v0, 4
    syscall

    li   $a0, 30000            # 30 s
    jal  delay_ms

    j    bucle_semaforo

#####################################################################
# delay_ms: espera activa de $a0 milisegundos usando el reloj del
# sistema (syscall 30). No usa registros que la ISR modifique, por
# lo que es seguro que una interrupcion ocurra durante la espera.
#####################################################################
delay_ms:
    move $s0, $a0          # $s0 = duracion pedida (registro "salvado")

    li   $v0, 30
    syscall                # $a0 = tiempo actual (ms, parte baja)
    move $s1, $a0          # $s1 = instante inicial

espera_delay:
    li   $v0, 30
    syscall
    subu $t3, $a0, $s1     # tiempo transcurrido
    blt  $t3, $s0, espera_delay

    jr   $ra
