;códigos de sálida
CODIGO_EXITO EQU 0
CODIGO_COMANDO_INVALIDO EQU 1
CODIGO_PARAMETRO_INVALIDO EQU 2
CODIGO_ESCRITURA_INVALIDA EQU 4
CODIGO_NODO_EXISTENTE EQU 8
;puertos
PUERTO_ENTRADA EQU 20
PUERTO_SALIDA EQU 21
PUERTO_LOG EQU 22

.data  ; Segmento de datos

.code  ; Segmento de código

.ports ; Definición de puertos
PUERTO_ENTRADA :
PUERTO_SALIDA:
PUERTO_LOG:

.interrupts ; Manejadores de interrupciones
; Ejemplo interrupcion del timer
;!INT 8 1
;  iret
;!ENDINT