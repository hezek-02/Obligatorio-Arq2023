;códigos de sálida
CODIGO_EXITO EQU 0
CODIGO_COMANDO_INVALIDO EQU 1
CODIGO_PARAMETRO_INVALIDO EQU 2
CODIGO_ESCRITURA_INVALIDA EQU 4
CODIGO_NODO_EXISTENTE EQU 8

PUERTO_ENTRADA EQU 20;
PUERTO_SALIDA EQU 21;
PUERTO_LOG EQU 22;
.data  ; Segmento de datos
	#define ES 0x0500
	nodoDinamico dw 0 ;indica el nodoActual (el último) en el modo dinámico
	modo dw 0 ;comienza en estático, indica el modo del árbol
.code  ; Segmento de código

;menú
menuSeleccion:
	XOR SI,SI ;Si=0, lo reinicia
	MOV AX,64 ;utilizo para desplegar codigo
	OUT PUERTO_LOG,AX ;imprime 64
	IN AX,PUERTO_ENTRADA 
	OUT PUERTO_LOG,AX ;imprime parametro

	CMP  AX,1 ;Cambiar Modo
		JE cambiar_modo
	CMP  AX,2 ;Agregar Nodo
		JE agregar_nodo
	CMP  AX,3 ;Calcular Altura
		JE calcular_altura
	CMP  AX,4 ;Calcular Suma
		JE calcular_suma
	CMP  AX,5 ;Imprimir Árbol
		JE imprimir_arbol
	CMP  AX,6 ;Imprimir Memoria
		JE imprimir_memoria
	CMP  AX,255 ;Detener programa
		JE fin
	MOV AX,CODIGO_COMANDO_INVALIDO	
	OUT PUERTO_LOG,AX
	JMP menuSeleccion

cambiar_modo:
	MOV word ptr DS:[nodoDinamico],0 ; resetea siempre el último nodo registrado 
	IN  AX,PUERTO_ENTRADA ; obtiene parametro
	OUT PUERTO_LOG,AX ; imprime parametro
	MOV word ptr DS:[modo],AX ; actualiza modo según parametro
	JMP inicializar_memoria

agregar_nodo:
	XOR SI,SI ; parametro de nro de pos/nodo
	IN AX,PUERTO_ENTRADA
	OUT PUERTO_LOG,AX ; imprime parámetro de entrada
	CMP word ptr DS:[modo],0
		JE agregarNodoEst
	CMP word ptr DS:[modo],0
		JE agregarNodoDin
	MOV AX,CODIGO_PARAMETRO_INVALIDO ;parametro inválido
	OUT PUERTO_LOG,AX
	JMP menuSeleccion
	agregarNodoEst:
		CALL agregarNodoEstatico
		JMP menuSeleccion
	agregarNodoDin:
		CALL agregarNodoDinamico
		JMP menuSeleccion
	
agregarNodoEstatico PROC
	PUSH AX ;ES:[BP + 4]
	PUSH SI ;ES:[BP + 2]
	PUSH BP
	MOV BP,SP

	MOV SI,[BP+2] ;desplz 
	MOV AX,[BP+4] ;nro a insertar

	;debug
	;MOV CX,AX
	;MOV AX,ES:[SI]
	;OUT PUERTO_LOG,AX
	;MOV AX,CX
	;OUT PUERTO_LOG,AX

	CMP ES:[SI],0x8000	
		JE	insertar
	CMP SI, 2048; no se considera signo
		JG error_excede
	CMP AX, ES:[SI]; se considera signo
		JNLE insercion_der ;>
	;CMP AX,ES:[SI]
		JL 	insercion_izq ;<
	JMP error_ya_existe;==
	error_excede:
		MOV AX,CODIGO_ESCRITURA_INVALIDA
		OUT PUERTO_LOG,AX
		JMP finalizarRecursion
	error_ya_existe:
		MOV AX,CODIGO_NODO_EXISTENTE
		OUT PUERTO_LOG,AX
		JMP finalizarRecursion
	insercion_der:
		ADD SI,SI
		ADD SI,4
		CALL agregarNodoEstatico
		JMP finalizarRecursion
	insercion_izq:
		ADD SI,SI
		ADD SI,2
		CALL agregarNodoEstatico
		JMP finalizarRecursion
	insertar:
		MOV	ES:[SI],AX ;agrega el nodo
		MOV AX,CODIGO_EXITO  
		OUT PUERTO_LOG,AX
		JMP finalizarRecursion

	finalizarRecursion:
		POP BP
		POP SI
		POP AX
		RET			
agregarNodoEstatico ENDP

agregarNodoDinamico PROC
	RET
agregarNodoDinamico ENDP

calcular_altura:

calcular_suma:

imprimir_arbol:

imprimir_memoria:

inicializar_memoria: ;iterativo (sirve dinámico y estático)
	MOV ES:[SI],0x8000
	ADD SI,2;pasos de offset 2 bytes
	CMP SI,2048 ;compara si ha llenado toda el area de memoria
		JLE inicializar_memoria 
	;debug
	;MOV AX,SI
	;OUT PUERTO_LOG,AX
	MOV AX,CODIGO_EXITO 
	OUT PUERTO_LOG,AX
	JMP	menuSeleccion

fin:
	
.ports ; Definición de puertos
20: 1,0,2,5,2,-1,2,5,2,7,2,8,2,9,2,10,2,11,2,12,2,13,2,14,2,15,2,16,2,17,2,18,255
21: 
;22: 64,1,0,0,64,2,5,0,64,2,-1,0,64,2,5,8,64,2,7,0,64,2,8,0,64,2,9,0,64,2,10,0,64,2,11,0,64,2,12,0,64,2,13,0,64,2,14,0,64,2,15,0,64,2,16,0,64,2,17,4,64,2,18,4,64,255,0

.interrupts ; Manejadores de interrupciones
; Ejemplo interrupcion del timer
;!INT 8 1
;  iret
;!ENDINT

