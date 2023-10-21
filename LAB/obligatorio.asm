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

;definiciones de llamadas
agregar_nodo:
	XOR SI,SI ; parametro de nro de pos/nodo

	IN AX,PUERTO_ENTRADA
	OUT PUERTO_LOG,AX ; imprime parámetro de entrada

	CMP word ptr DS:[modo],0
		JE agregarNodoEst
	CMP word ptr DS:[modo],1
		JE agregarNodoDin
	JMP errorParametroInvalido
	agregarNodoEst:
		CALL agregarNodoEstatico
		JMP menuSeleccion
	agregarNodoDin:
		CALL agregarNodoDinamico
		JMP menuSeleccion

imprimir_memoria:
	XOR SI,SI

	IN AX,PUERTO_ENTRADA
	OUT PUERTO_LOG,AX ; imprime parámetro de entrada (N)

	CMP word ptr DS:[modo], 0
		JE imprimir_memoriaEstaticoPrev
	CMP word ptr DS:[modo], 1
		JE imprimir_memoriaDinamicoPrev
	JMP errorParametroInvalido
	imprimir_memoriaEstaticoPrev:
		CMP AX, 2048
			JNLE errorParametroInvalido
		SHL AX, 1
		JMP imprimir_memoria_din_est
	imprimir_memoriaDinamicoPrev:
		CMP AX,682
			JNLE errorParametroInvalido
		MOV CX, 2 ; mul 6
		MOV BX, AX
		SHL AX, CL; mul 4
		ADD AX,BX
		ADD AX,BX;fin mul 6
		
		JMP imprimir_memoria_din_est
	
;implementaciones de CU's
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
	CMP SI, 4096; no se considera signo
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
	PUSH AX ;ES:[BP + 4]
	PUSH SI ;ES:[BP + 2]
	PUSH BP
	MOV BP,SP

	MOV SI,[BP+2] ;desplz 
	MOV AX,[BP+4] ;nro a insertar

	;debug
	;MOV CX,AX
	;MOV AX,SI
	;OUT PUERTO_LOG,AX
	;MOV AX,CX
	MOV CX, 2; para multiplicar por 4, SHL

	CMP ES:[SI],0x8000	
		JE	insertarDinamico
	CMP SI, 1365; no se considera signo 4096/3
		JG error_excede_din
	CMP AX, ES:[SI]; se considera signo
		JNLE insercion_der_din ;>
	;CMP AX,ES:[SI]
		JL 	insercion_izq_din ;<
	JMP error_ya_existe_din;==
	error_excede_din:
		MOV AX,CODIGO_ESCRITURA_INVALIDA
		OUT PUERTO_LOG,AX
		JMP finalizarRecursionDinamico
	error_ya_existe_din:
		MOV AX,CODIGO_NODO_EXISTENTE
		OUT PUERTO_LOG,AX
		JMP finalizarRecursionDinamico
	insercion_der_din:
		CMP ES:[SI+4], 0x8000
			JE elseDer
		MOV BX, ES:[SI+4] ; agregarNodoDinamico(num, 3*AREA_DE_MEMORIA[pos+2]);
		SHL BX, CL ; multiplico por 4
		ADD BX, ES:[SI+4] ; sumo ES:[SI+4]
		ADD BX, ES:[SI+4] ; sumo ES:[SI+4]

		MOV SI, BX
		CALL agregarNodoDinamico
		JMP finalizarRecursionDinamico
		elseDer: 
			ADD SI,4
			CALL agregarNodoDinamico
			JMP finalizarRecursionDinamico
	insercion_izq_din:
		CMP ES:[SI+2], 0x8000
			JE elseIzq
		MOV BX, ES:[SI+2] ; agregarNodoDinamico(num, 3*AREA_DE_MEMORIA[pos+1]);
		SHL BX, CL ; multiplico por 4
		ADD BX, ES:[SI+2] ; sumo ES:[SI+2]
		ADD BX, ES:[SI+2] ; sumo ES:[SI+2]
		MOV SI, BX
		CALL agregarNodoDinamico
		JMP finalizarRecursionDinamico
		elseIzq:
			ADD SI,2
			CALL agregarNodoDinamico
			JMP finalizarRecursionDinamico
	insertarDinamico:
		CMP SI,0 ; inserta el primer nodo
			JE insertarPrimero
		INC word ptr DS:[nodoDinamico] ; nodoDinamico++; 
		MOV BX, DS:[nodoDinamico]
		MOV word ptr ES:[SI],BX ; AREA_DE_MEMORIA[pos] = nodoDinamico;
		 
		; agregarNodoDinamico(num, 3*AREA_DE_MEMORIA[pos+1]);
		SHL BX, CL ; multiplico por 4
		ADD BX, DS:[nodoDinamico]; sumo nodoDinamico
		ADD BX, DS:[nodoDinamico]; sumo nodoDinamico
		MOV SI, BX ;SI = [6*nodoDinamico];

		
		MOV	ES:[SI],AX ; agrega el nodo
		MOV AX,CODIGO_EXITO  
		OUT PUERTO_LOG,AX
		JMP finalizarRecursionDinamico

	insertarPrimero:
		MOV	ES:[SI],AX
		MOV AX,CODIGO_EXITO  
		OUT PUERTO_LOG,AX
		JMP finalizarRecursion
	finalizarRecursionDinamico:
		POP BP
		POP SI
		POP AX
		RET			

	RET
agregarNodoDinamico ENDP

calcular_altura:

calcular_suma:

imprimir_arbol:

imprimir_memoria_din_est:
	CMP SI,AX
		JNL menuSeleccion
	PUSH AX
	MOV AX, ES:[SI]
	OUT PUERTO_SALIDA, AX
	POP AX
	ADD SI, 2
	JMP imprimir_memoria_din_est

inicializar_memoria: ;iterativo (sirve dinámico y estático)
	MOV ES:[SI],0x8000
	ADD SI,2;pasos de offset 2 bytes
	CMP SI,4096;compara si ha llenado toda el area de memoria
		JLE inicializar_memoria 
	;debug
	;MOV AX,SI
	;OUT PUERTO_LOG,AX
	MOV AX,CODIGO_EXITO 
	OUT PUERTO_LOG,AX
	JMP	menuSeleccion

errorParametroInvalido:
	MOV AX,CODIGO_PARAMETRO_INVALIDO ;parametro inválido
	OUT PUERTO_LOG,AX
	JMP menuSeleccion

fin:
	
.ports ; Definición de puertos
;20: 1,0,2,5,2,-4,2,-10,2,-80,2,60,6,0,6,1,6,10,1,1,2,5,2,-4,2,-10,2,-80,2,60,6,0,6,1,6,10,255
;21: 5,5,-4,60,-10,-32768,-32768,-32768,-80,-32768,-32768,5,1,4,5,1,4,-4,2,-32768,-10,3,-32768,-80,-32768,-32768,60,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768
;22: 64,1,0,0,64,2,5,0,64,2,-4,0,64,2,-10,0,64,2,-80,0,64,2,60,0,64,6,0,0,64,6,1,0,64,6,10,0,64,1,1,0,64,2,5,0,64,2,-4,0,64,2,-10,0,64,2,-80,0,64,2,60,0,64,6,0,0,64,6,1,0,64,6,10,0,64,255,0
;CU: test memoria

;20: 1,1,2,5,2,-5,2,-4,2,8,6,10,255
;21: 5,1,3,-5,-32768,2,-4,-32768,-32768,8,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768,-32768
;22: 64,1,1,0,64,2,5,0,64,2,-5,0,64,2,-4,0,64,2,8,0,64,6,10,0,64,255,0
;CU: agregar nodo dinámico

;20: 1,0,2,5,2,-1,2,5,2,7,2,8,2,9,2,10,2,11,2,12,2,13,2,14,2,15,2,16,2,17,2,18,255
;21: 
;22: 64,1,0,0,64,2,5,0,64,2,-1,0,64,2,5,8,64,2,7,0,64,2,8,0,64,2,9,0,64,2,10,0,64,2,11,0,64,2,12,0,64,2,13,0,64,2,14,0,64,2,15,0,64,2,16,0,64,2,17,4,64,2,18,4,64,255,0
;CU: agregar nodo estático
.interrupts ; Manejadores de interrupciones
; Ejemplo interrupcion del timer
;!INT 8 1
;  iret
;!ENDINT

