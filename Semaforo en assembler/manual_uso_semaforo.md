# Manual de Uso — Semáforo con Pulsador (MIPS32 / MARS)

**Archivo:** `semaforo_pulsador.asm`

## Descripción

Simula un semáforo controlado por la tecla `s`. Comienza en verde y
espera a que se presione el pulsador; a partir de ahí avanza por
amarillo y rojo con tiempos fijos, y vuelve a verde indefinidamente.
La detección de la tecla se implementa con una interrupción real de
hardware (no por sondeo), usando la herramienta de teclado/pantalla
de MARS.

## Requisitos

- MARS 4.5 (u otra versión compatible con MIPS32 e interrupciones).
- Herramienta **Keyboard and Display MMIO Simulator** (viene incluida en MARS).

## Pasos para ejecutar

1. Abrir `semaforo_pulsador.asm` en MARS (File > Open).
2. Ir a **Tools > Keyboard and Display MMIO Simulator**.
3. En esa ventana, pulsar **Connect to MIPS**. Este paso es obligatorio:
   sin conexión, el teclado no genera interrupciones y el programa se
   queda esperando el pulsador para siempre.
4. Volver a la ventana principal y pulsar **Assemble** (F3).
5. Pulsar **Run/Go** (F5). En la consola (Run I/O) aparecerá:
   `Semaforo en verde, esperando pulsador`.
6. Hacer clic dentro del recuadro **KEYBOARD** del simulador (no en la
   consola normal de MARS) y presionar la tecla **s**.
7. El programa mostrará "Pulsador activado..." y avanzará solo:
   - 20 s después → amarillo
   - 10 s después → rojo
   - 30 s después → vuelve a verde (y el ciclo se repite)
8. Para terminar, pulsar **Stop** en MARS, ya que el ciclo es infinito
   por diseño (tal como pide el enunciado).

## Notas técnicas

- La detección de la tecla `s` usa una interrupción de hardware real
  (bit 8 del registro `Cause`, según la implementación interna de
  MARS), atendida por una rutina de servicio en `0x80000180`.
- La temporización (20 s / 10 s / 30 s) se implementa consultando el
  reloj del sistema (`syscall 30`) en un bucle de espera, ya que MARS
  no ofrece un dispositivo de temporizador con interrupción periódica
  real como el de un MIPS físico.
- Si el programa no reacciona al presionar `s`, lo más común es que
  el simulador de teclado no esté conectado (paso 3) o que se haya
  hecho clic en la consola equivocada (paso 6).
