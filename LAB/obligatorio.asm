;códigos de sálida
CODIGO_EXITO EQU 0
CODIGO_COMANDO_INVALIDO EQU 1
CODIGO_PARAMETRO_INVALIDO EQU 2
CODIGO_ESCRITURA_INVALIDA EQU 4
CODIGO_NODO_EXISTENTE EQU 8

PUERTO_ENTRADA EQU 20;
PUERTO_SALIDA EQU 21;
PUERTO_LOG EQU 22;
AREA_MEMORIA EQU 2048
AREA_MEMORIA_BYTES EQU 2048 * 2
CANT_NODOS_DINAMICOS EQU 682
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

;definiciones de llamadas
cambiar_modo:;1
	MOV word ptr DS:[nodoDinamico],0 ; resetea siempre el último nodo registrado 
	IN  AX,PUERTO_ENTRADA ; obtiene parametro
	OUT PUERTO_LOG,AX ; imprime parametro
	CMP AX,1	
		JG errorParametroInvalido
	CMP AX,0
		JL errorParametroInvalido
	MOV word ptr DS:[modo],AX ; actualiza modo según parametro
	JMP inicializar_memoria

agregar_nodo:;2
	XOR SI,SI ; parametro de nro de pos/nodo

	IN AX,PUERTO_ENTRADA
	OUT PUERTO_LOG,AX ; imprime parámetro de entrada
	CMP AX,0x8000
		JE errorParametroInvalido
	;deriva rutina según modo
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

calcular_altura:;3
	XOR SI,SI
	XOR AX,AX
	XOR BX,BX
	XOR DX,DX
	MOV CX,2
	CMP word ptr DS:[modo],0
		JE calcular_altura_estaticoPrev
	CMP word ptr DS:[modo],1
		JE calcular_altura_dinamicoPrev
	JMP errorParametroInvalido
	calcular_altura_estaticoPrev:
		CALL calcular_altura_estatico
		OUT PUERTO_SALIDA,AX
		MOV AX,CODIGO_EXITO 
		OUT PUERTO_LOG,AX
		JMP menuSeleccion
	calcular_altura_dinamicoPrev:
		CALL calcular_altura_dinamico
		OUT PUERTO_SALIDA,AX
		MOV AX,CODIGO_EXITO 
		OUT PUERTO_LOG,AX
		JMP menuSeleccion

calcular_suma:;4
	XOR SI,SI 
	XOR AX,AX
	MOV CX,2 ;para usar el SHL
	;según modo deriva rutina
	CMP word ptr DS:[modo],0 
		JE calcular_suma_estaticoPrev
	CMP word ptr DS:[modo],1
		JE calcular_suma_dinamicoPrev
	JMP errorParametroInvalido
	calcular_suma_estaticoPrev:
		CALL calcular_suma_estatico
		OUT PUERTO_SALIDA,AX
		MOV AX,CODIGO_EXITO 
		OUT PUERTO_LOG,AX
		JMP menuSeleccion
	calcular_suma_dinamicoPrev:
		CALL calcular_suma_dinamico
		OUT PUERTO_SALIDA,AX
		MOV AX,CODIGO_EXITO 
		OUT PUERTO_LOG,AX
		JMP menuSeleccion

imprimir_arbol:;5
	XOR SI,SI
	MOV CX, 2
	IN AX,PUERTO_ENTRADA
	OUT PUERTO_LOG,AX ; imprime parámetro de entrada (orden)

	;según parametro imprime arbol de mayor o menor/viceversa
	CMP AX, 0
		JE imprimir_arbol_Prev
	CMP AX, 1
		JE imprimir_arbol_Prev
	JMP errorParametroInvalido
	
	;segun modo llama a la rutina cocrespoondiente
	imprimir_arbol_Prev:
		CMP word ptr DS:[modo],0
			JE imprimir_arbol_estaticoPrev
		CMP word ptr DS:[modo],1
			JE imprimir_arbol_dinamicoPrev
	JMP errorParametroInvalido

	imprimir_arbol_dinamicoPrev:
		CALL imprimir_arbol_dinamico
		MOV AX,CODIGO_EXITO 
		OUT PUERTO_LOG,AX
		JMP menuSeleccion
	imprimir_arbol_estaticoPrev:
		CALL imprimir_arbol_estatico
		MOV AX,CODIGO_EXITO 
		OUT PUERTO_LOG,AX
		JMP menuSeleccion


imprimir_memoria:;6
	XOR SI,SI

	IN AX,PUERTO_ENTRADA
	OUT PUERTO_LOG,AX ; imprime parámetro de entrada (N)
	CMP AX, 0
		JL errorParametroInvalido
	CMP word ptr DS:[modo], 0
		JE imprimir_memoriaEstaticoPrev
	CMP word ptr DS:[modo], 1
		JE imprimir_memoriaDinamicoPrev
	JMP errorParametroInvalido
	imprimir_memoriaEstaticoPrev:
		CMP AX, AREA_MEMORIA_BYTES
			JNLE errorParametroInvalido
		SHL AX, 1
		JMP imprimir_memoria_din_est
	imprimir_memoriaDinamicoPrev:
		CMP AX,CANT_NODOS_DINAMICOS
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

	CMP ES:[SI],0x8000	
		JE	insertar
	CMP SI, AREA_MEMORIA_BYTES; no se considera signo
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

	MOV CX, 2; para multiplicar por 4, SHL

	CMP ES:[SI],0x8000	
		JE	insertarDinamico
	CMP SI, AREA_MEMORIA_BYTES; 
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
agregarNodoDinamico ENDP

calcular_altura_dinamico PROC
	PUSH SI
	PUSH DX ;alt izq
	PUSH BX ;alt der
    PUSH BP
    MOV BP, SP

    MOV SI, [BP + 6]
	CMP SI,AREA_MEMORIA_BYTES	
		JG	fin_altura_dinamico
    CMP ES:[SI], 0x8000
    	JE fin_altura_dinamico

    ; Calcular alturas de las subárboles izquierdo y derecho
   	MOV BX, [BP+2]
	INC BX ;altDerecha

	CMP ES:[SI+4] , 0x8000
		JE saltar_ejec_altura_der
	PUSH BX
	MOV BX, ES:[SI+4] 
	SHL BX, CL ; multiplico por 4
	ADD BX, ES:[SI+4] ; sumo ES:[SI+4]
	ADD BX, ES:[SI+4] ; sumo ES:[SI+4]
	MOV SI,BX
	POP BX

    CALL calcular_altura_dinamico

	saltar_ejec_altura_der:
	MOV SI, [BP+6]

	CMP ES:[SI+2] , 0x8000
		JE saltar_ejec_altura_izq

	PUSH BX
	MOV BX, ES:[SI+2] 
	SHL BX, CL ; multiplico por 4
	ADD BX, ES:[SI+2] ; sumo ES:[SI+4]
	ADD BX, ES:[SI+2] ; sumo ES:[SI+4]
	MOV SI,BX
	POP BX

	MOV DX, [BP+4]
  	INC DX ;altIzq

    CALL calcular_altura_dinamico

	saltar_ejec_altura_izq:

    ; Comparar alturas y retornar la mayor
	
    CMP BX, DX ; si bx es mayor
    	JG mayor_es_derecho
	CMP AX, DX ; si ax es mayor
		JG fin_altura_dinamico
    MOV AX, DX ; Retornar altIzquierda
    JMP fin_altura_dinamico

	mayor_es_derecho:	
	CMP AX,BX ; si ax es mayor
		JG fin_altura_estatico
    MOV AX, BX ; Retornar altDerecha

	fin_altura_dinamico:
    	POP BP
		POP BX
		POP DX
		POP SI
    	RET
calcular_altura_dinamico ENDP

calcular_altura_estatico PROC
	PUSH SI
	PUSH DX ;alt izq
	PUSH BX ;alt der
    PUSH BP
    MOV BP, SP
    MOV SI, [BP + 6]

	CMP SI,AREA_MEMORIA_BYTES	
		JG	fin_altura_estatico
    CMP ES:[SI], 0x8000
    	JE fin_altura_estatico
    ; Calcular alturas de las subárboles izquierdo y derecho
	SHL SI,1
	ADD SI,4

	MOV BX, [BP+2]
	INC BX
    CALL calcular_altura_estatico

	MOV SI,[BP+6]

	SHL SI,1
	ADD SI,2

	MOV DX, [BP+4]
  	INC DX ;altIzq
    CALL calcular_altura_estatico

    ; Comparar alturas y retornar la mayor
	
    CMP BX, DX ; si bx es mayor
    	JG mayor_es_derecho_estatico
	CMP AX, DX ; si ax es mayor
		JG fin_altura_estatico
    MOV AX, DX ; Retornar altIzquierda
    JMP fin_altura_estatico

	mayor_es_derecho_estatico:	
	CMP AX,BX ; si ax es mayor
		JG fin_altura_estatico
    MOV AX, BX ; Retornar altDerecha

	fin_altura_estatico:
		POP BP
		POP BX ;alt izq
		POP DX ;alt der
    	POP SI
		RET
calcular_altura_estatico ENDP
		
calcular_suma_dinamico PROC
	PUSH SI ;ES:[BP + 2]
	PUSH BP
	MOV BP,SP

	MOV SI,[BP+2] ;desplz 

	CMP SI,AREA_MEMORIA_BYTES	
		JG	fin_suma_dinamica

	CMP ES:[SI], 0x8000
		JE fin_suma_dinamica

	ADD AX,ES:[SI]

	MOV BX, ES:[SI+4] 
	CMP BX, 0x8000
		JE saltar_ejec_suma
	SHL BX, CL ; multiplico por 4
	ADD BX, ES:[SI+4] ; sumo ES:[SI+4]
	ADD BX, ES:[SI+4] ; sumo ES:[SI+4]
	MOV SI,BX

	CALL calcular_suma_dinamico
	
	saltar_ejec_suma:

	MOV SI, [BP+2]
	MOV BX, ES:[SI+2] 
	CMP BX, 0x8000
		JE fin_suma_dinamica
	SHL BX, CL ; multiplico por 4
	ADD BX, ES:[SI+2] ; sumo ES:[SI+4]
	ADD BX, ES:[SI+2] ; sumo ES:[SI+4]
	MOV SI,BX

	CALL calcular_suma_dinamico

	fin_suma_dinamica:
		POP BP
    	POP SI
		RET
calcular_suma_dinamico ENDP

calcular_suma_estatico PROC
	PUSH SI ;ES:[BP + 2]
	PUSH BP
	MOV BP,SP

	MOV SI,[BP+2] ;desplz 

	CMP SI,AREA_MEMORIA_BYTES	
		JG	fin_suma_estatica
	CMP ES:[SI], 0x8000
		JE fin_suma_estatica
	
	ADD AX,ES:[SI]

	SHL SI,1
	ADD SI,2

	CALL calcular_suma_estatico

	MOV SI, [BP+2]
	SHL SI,1
	ADD SI,4

	CALL calcular_suma_estatico

	fin_suma_estatica:
		POP BP
		POP SI
		RET
calcular_suma_estatico ENDP

imprimir_arbol_dinamico PROC
	PUSH AX ;ES:[BP + 4]
	PUSH SI ;ES:[BP + 2]
	PUSH BP
	MOV BP,SP

	MOV SI,[BP+2] ;desplz 
	MOV AX,[BP+4] ;orden
	
	CMP SI,AREA_MEMORIA_BYTES	
		JG	finalizar_recursion_imprimir_dinamico

	CMP ES:[SI],0x8000	
		JE	finalizar_recursion_imprimir_dinamico
	
	CMP AX, 1 ; mayor a menor
		JE imprimir_mayor_a_menor_dinamico ;>
	CMP AX,0 ;menor a mayor
		JE imprimir_menor_a_mayor_dinamico ;<

	imprimir_menor_a_mayor_dinamico:

		MOV BX, ES:[SI+2] 
		CMP BX, 0x8000
			JE saltar_ejec_menor_a_mayor
		SHL BX, CL ; multiplico por 4
		ADD BX, ES:[SI+2] ; sumo ES:[SI+4]
		ADD BX, ES:[SI+2] ; sumo ES:[SI+4]
		MOV SI,BX

		CALL imprimir_arbol_dinamico;imprimirArbolDinamico(3*AREA_DE_MEMORIA[pos+1],orden);
		
		saltar_ejec_menor_a_mayor:
		
		PUSH AX
		MOV SI, [BP+2];sigue del índice con la ejecución del stack correspondiente
		MOV AX, ES:[SI]
		OUT PUERTO_SALIDA,AX
		POP AX
		
		MOV BX, ES:[SI+4]
		CMP BX, 0x8000
			JE finalizar_recursion_imprimir_dinamico
		SHL BX, CL ; multiplico por 4
		ADD BX, ES:[SI+4] ; sumo ES:[SI+2]
		ADD BX, ES:[SI+4] ; sumo ES:[SI+2]
		MOV SI,BX

		CALL imprimir_arbol_dinamico;imprimirArbolDinamico(3*AREA_DE_MEMORIA[pos+2],orden);

		JMP finalizar_recursion_imprimir_dinamico
	imprimir_mayor_a_menor_dinamico:
		
		MOV BX, ES:[SI+4] 

		CMP BX, 0x8000
			JE saltar_ejec_mayor_a_menor
		SHL BX, CL ; multiplico por 4
		ADD BX, ES:[SI+4] ; sumo ES:[SI+4]
		ADD BX, ES:[SI+4] ; sumo ES:[SI+4]
		MOV SI,BX
		
		CALL imprimir_arbol_dinamico;imprimirArbolDinamico(3*AREA_DE_MEMORIA[pos+2],orden);
		
		saltar_ejec_mayor_a_menor:
	
		PUSH AX
		MOV SI, [BP+2] ;sigue del índice con la ejecución del stack correspondiente
		MOV AX, ES:[SI]
		OUT PUERTO_SALIDA,AX
		POP AX

		MOV BX, ES:[SI+2]
		CMP BX, 0x8000
			JE finalizar_recursion_imprimir_dinamico
		SHL BX, CL ; multiplico por 4
		ADD BX, ES:[SI+2] ; sumo ES:[SI+2]
		ADD BX, ES:[SI+2] ; sumo ES:[SI+2]
		MOV SI,BX

		CALL imprimir_arbol_dinamico;imprimirArbolDinamico(3*AREA_DE_MEMORIA[pos+1],orden);

	finalizar_recursion_imprimir_dinamico:
		POP BP
		POP SI
		POP AX
		RET
imprimir_arbol_dinamico ENDP

imprimir_arbol_estatico PROC;1 mayor a menor, 0 menor a mayor (5)
	
	PUSH AX ;ES:[BP + 4]
	PUSH SI ;ES:[BP + 2]
	PUSH BP
	MOV BP,SP

	MOV SI,[BP+2] ;desplz 
	MOV AX,[BP+4] ;orden

	CMP SI,AREA_MEMORIA_BYTES	
		JG	finalizar_recursion_imprimir
	CMP ES:[SI],0x8000	
		JE	finalizar_recursion_imprimir
	
	CMP AX, 1 ; mayor a menor
		JE imprimir_mayor_a_menor_estatico ;>
	CMP AX,0 ;menor a mayor
		JE imprimir_menor_a_mayor_estatico ;<

	imprimir_menor_a_mayor_estatico:
		SHL SI,1
		ADD SI,2
		CALL imprimir_arbol_estatico;imprimirArbol(2*(nodo+1)-1,orden);

		PUSH AX
		MOV SI, [BP+2];sigue del índice con la ejecución del stack correspondiente
		MOV AX, ES:[SI]
		OUT PUERTO_SALIDA,AX
		POP AX

		SHL SI,1
		ADD SI,4
		CALL imprimir_arbol_estatico;imprimirArbol(2*(nodo+1),orden);

		JMP finalizar_recursion_imprimir
	imprimir_mayor_a_menor_estatico:
		SHL SI,1
		ADD SI,4
		CALL imprimir_arbol_estatico;imprimirArbol(2*(nodo+1),orden);
		
		PUSH AX
		MOV SI, [BP+2] ;sigue del índice con la ejecución del stack correspondiente
		MOV AX, ES:[SI]
		OUT PUERTO_SALIDA,AX
		POP AX

		SHL SI,1
		ADD SI,2
		CALL imprimir_arbol_estatico;imprimirArbol(2*(nodo+1)-1,orden);

	finalizar_recursion_imprimir:
		POP BP
		POP SI
		POP AX
		RET
imprimir_arbol_estatico ENDP

imprimir_memoria_din_est:  ;iterativo (sirve dinámico y estático), se inicializa AX, con el valor N, según corresponda
	CMP SI,AX
		JNL fin_imprimir_memoria
	PUSH AX
	MOV AX, ES:[SI]
	OUT PUERTO_SALIDA, AX
	POP AX
	ADD SI, 2
	JMP imprimir_memoria_din_est
	fin_imprimir_memoria:
		MOV AX, CODIGO_EXITO
		OUT PUERTO_LOG, AX
		JMP menuSeleccion

inicializar_memoria: ;iterativo (sirve dinámico y estático)
	MOV ES:[SI],0x8000
	ADD SI,2;pasos de offset 2 bytes
	CMP SI,AREA_MEMORIA_BYTES;compara si ha llenado toda el area de memoria
		JLE inicializar_memoria 
	MOV AX,CODIGO_EXITO 
	OUT PUERTO_LOG,AX
	JMP	menuSeleccion

errorParametroInvalido:
	MOV AX,CODIGO_PARAMETRO_INVALIDO ;parametro inválido
	OUT PUERTO_LOG,AX
	JMP menuSeleccion

fin:
	MOV AX,CODIGO_EXITO 
	OUT PUERTO_LOG,AX

.ports ; Definición de puertos
20: 1,0,2,100,2,200,2,50,2,30,2,150,4,1,1,2,102,2,202,2,52,2,32,2,152,4,255
.interrupts ; Manejadores de interrupciones
; Ejemplo interrupcion del timer
;!INT 8 1
;  iret
;!ENDINT

