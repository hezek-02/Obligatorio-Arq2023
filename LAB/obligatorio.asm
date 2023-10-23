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

	MOV CX, 2; para multiplicar por 4, SHL

	CMP ES:[SI],0x8000	
		JE	insertarDinamico
	CMP SI, 4096; no se considera signo 4096/3
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
	CMP SI,4096	
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

	CMP SI,4096	
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

	CMP SI,4096	
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
		PUSH BP
		PUSH BX ;alt izq
		PUSH DX ;alt der
    	PUSH SI
		RET
calcular_suma_dinamico ENDP

calcular_suma_estatico PROC
	PUSH SI ;ES:[BP + 2]
	PUSH BP
	MOV BP,SP

	MOV SI,[BP+2] ;desplz 

	CMP SI,4096	
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
	
	CMP SI,4096	
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

	CMP SI,4096	
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
	CMP SI,4096;compara si ha llenado toda el area de memoria
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
20:1,1,2,3,2,4,2,5,2,6,2,7,2,8,2,9,2,10,2,11,2,12,2,13,2,14,2,15,2,16,2,17,2,18,2,19,2,20,2,21,2,22,2,23,2,24,2,25,2,26,2,27,2,28,2,29,2,30,2,31,2,32,2,33,2,34,2,35,2,36,2,37,2,38,2,39,2,40,2,41,2,42,2,43,2,44,2,45,2,46,2,47,2,48,2,49,2,50,2,51,2,52,2,53,2,54,2,55,2,56,2,57,2,58,2,59,2,60,2,61,2,62,2,63,2,64,2,65,2,66,2,67,2,68,2,69,2,70,2,71,2,72,2,73,2,74,2,75,2,76,2,77,2,78,2,79,2,80,2,81,2,82,2,83,2,84,2,85,2,86,2,87,2,88,2,89,2,90,2,91,2,92,2,93,2,94,2,95,2,96,2,97,2,98,2,99,2,100,2,101,2,102,2,103,2,104,2,105,2,106,2,107,2,108,2,109,2,110,2,111,2,112,2,113,2,114,2,115,2,116,2,117,2,118,2,119,2,120,2,121,2,122,2,123,2,124,2,125,2,126,2,127,2,128,2,129,2,130,2,131,2,132,2,133,2,134,2,135,2,136,2,137,2,138,2,139,2,140,2,141,2,142,2,143,2,144,2,145,2,146,2,147,2,148,2,149,2,150,2,151,2,152,2,153,2,154,2,155,2,156,2,157,2,158,2,159,2,160,2,161,2,162,2,163,2,164,2,165,2,166,2,167,2,168,2,169,2,170,2,171,2,172,2,173,2,174,2,175,2,176,2,177,2,178,2,179,2,180,2,181,2,182,2,183,2,184,2,185,2,186,2,187,2,188,2,189,2,190,2,191,2,192,2,193,2,194,2,195,2,196,2,197,2,198,2,199,2,200,2,201,2,202,2,203,2,204,2,205,2,206,2,207,2,208,2,209,2,210,2,211,2,212,2,213,2,214,2,215,2,216,2,217,2,218,2,219,2,220,2,221,2,222,2,223,2,224,2,225,2,226,2,227,2,228,2,229,2,230,2,231,2,232,2,233,2,234,2,235,2,236,2,237,2,238,2,239,2,240,2,241,2,242,2,243,2,244,2,245,2,246,2,247,2,248,2,249,2,250,2,251,2,252,2,253,2,254,2,255,2,256,2,257,2,258,2,259,2,260,2,261,2,262,2,263,2,264,2,265,2,266,2,267,2,268,2,269,2,270,2,271,2,272,2,273,2,274,2,275,2,276,2,277,2,278,2,279,2,280,2,281,2,282,2,283,2,284,2,285,2,286,2,287,2,288,2,289,2,290,2,291,2,292,2,293,2,294,2,295,2,296,2,297,2,298,2,299,2,300,2,301,2,302,2,303,2,304,2,305,2,306,2,307,2,308,2,309,2,310,2,311,2,312,2,313,2,314,2,315,2,316,2,317,2,318,2,319,2,320,2,321,2,322,2,323,2,324,2,325,2,326,2,327,2,328,2,329,2,330,2,331,2,332,2,333,2,334,2,335,2,336,2,337,2,338,2,339,2,340,2,341,2,342,2,343,2,344,2,345,2,346,2,347,2,348,2,349,2,350,2,351,2,352,2,353,2,354,2,355,2,356,2,357,2,358,2,359,2,360,2,361,2,362,2,363,2,364,2,365,2,366,2,367,2,368,2,369,2,370,2,371,2,372,2,373,2,374,2,375,2,376,2,377,2,378,2,379,2,380,2,381,2,382,2,383,2,384,2,385,2,386,2,387,2,388,2,389,2,390,2,391,2,392,2,393,2,394,2,395,2,396,2,397,2,398,2,399,2,400,2,401,2,402,2,403,2,404,2,405,2,406,2,407,2,408,2,409,2,410,2,411,2,412,2,413,2,414,2,415,2,416,2,417,2,418,2,419,2,420,2,421,2,422,2,423,2,424,2,425,2,426,2,427,2,428,2,429,2,430,2,431,2,432,2,433,2,434,2,435,2,436,2,437,2,438,2,439,2,440,2,441,2,442,2,443,2,444,2,445,2,446,2,447,2,448,2,449,2,450,2,451,2,452,2,453,2,454,2,455,2,456,2,457,2,458,2,459,2,460,2,461,2,462,2,463,2,464,2,465,2,466,2,467,2,468,2,469,2,470,2,471,2,472,2,473,2,474,2,475,2,476,2,477,2,478,2,479,2,480,2,481,2,482,2,483,2,484,2,485,2,486,2,487,2,488,2,489,2,490,2,491,2,492,2,493,2,494,2,495,2,496,2,497,2,498,2,499,2,500,2,501,2,502,2,503,2,504,2,505,2,506,2,507,2,508,2,509,2,510,2,511,2,768,2,769,2,770,2,771,2,772,2,773,2,774,2,775,2,776,2,777,2,778,2,779,2,780,2,781,2,782,2,783,2,784,2,785,2,786,2,787,2,788,2,789,2,790,2,791,2,792,2,793,2,794,2,795,2,796,2,797,2,798,2,799,2,800,2,801,2,802,2,803,2,804,2,805,2,806,2,807,2,808,2,809,2,810,2,811,2,812,2,813,2,814,2,815,2,816,2,817,2,818,2,819,2,820,2,821,2,822,2,823,2,824,2,825,2,826,2,827,2,828,2,829,2,830,2,831,2,832,2,833,2,834,2,835,2,836,2,837,2,838,2,839,2,840,2,841,2,842,2,843,2,844,2,845,2,846,2,847,2,848,2,849,2,850,2,851,2,852,2,853,2,854,2,855,2,856,2,857,2,858,2,859,2,860,2,861,2,862,2,863,2,864,2,865,2,866,2,867,5,1,255

;20:1,0,2,1024,2,512,2,256,2,128,2,64,2,32,2,16,2,8,2,4,2,2,2,1,2,3,2,5,2,6,2,7,2,9,2,10,2,11,2,12,2,13,2,14,2,15,2,17,2,18,2,19,2,20,2,21,2,22,2,23,2,24,2,25,2,26,2,27,2,28,2,29,2,30,2,31,2,33,2,34,2,35,2,36,2,37,2,38,2,39,2,40,2,41,2,42,2,43,2,44,2,45,2,46,2,47,2,48,2,49,2,50,2,51,2,52,2,53,2,54,2,55,2,56,2,57,2,58,2,59,2,60,2,61,2,62,2,63,2,65,2,66,2,67,2,68,2,69,2,70,2,71,2,72,2,73,2,74,2,75,2,76,2,77,2,78,2,79,2,80,2,81,2,82,2,83,2,84,2,85,2,86,2,87,2,88,2,89,2,90,2,91,2,92,2,93,2,94,2,95,2,96,2,97,2,98,2,99,2,100,2,101,2,102,2,103,2,104,2,105,2,106,2,107,2,108,2,109,2,110,2,111,2,112,2,113,2,114,2,115,2,116,2,117,2,118,2,119,2,120,2,121,2,122,2,123,2,124,2,125,2,126,2,127,2,2048,2,1025,2,1026,2,1027,2,1028,2,1029,2,1030,2,1031,2,1032,2,1033,2,1034,2,1035,2,1036,2,1037,2,1038,2,1039,2,1040,2,1041,2,1042,2,1043,2,1044,2,1045,2,1046,2,1047,2,1048,2,1049,2,1050,2,1051,2,1052,2,1053,2,1054,2,1055,2,1056,2,1057,2,1058,2,1059,2,1060,2,1061,2,1062,2,1063,2,1064,2,1065,2,1066,2,1067,2,1068,2,1069,2,1070,2,1071,2,1072,2,1073,2,1074,2,1075,2,1076,2,1077,2,1078,2,1079,2,1080,2,1081,2,1082,2,1083,2,1084,2,1085,2,1086,2,1087,2,1088,2,1089,2,1090,2,1091,2,1092,2,1093,2,1094,2,1095,2,1096,2,1097,2,1098,2,1099,2,1100,2,1101,2,1102,2,1103,2,1104,2,1105,2,1106,2,1107,2,1108,2,1109,2,1110,2,1111,2,1112,2,1113,2,1114,2,1115,2,1116,2,1117,2,1118,2,1119,2,1120,2,1121,2,1122,2,1123,2,1124,2,1125,2,1126,2,1127,2,1128,2,1129,2,1130,2,1131,2,1132,2,1133,2,1134,2,1135,2,1136,2,1137,2,1138,2,1139,2,1140,2,1141,2,1142,5,1,255
;Puerto 21: 2048, 1033, 1032, 1031, 1030, 1029, 1028, 1027, 1026, 1025, 1024, 512, 256, 128, 70, 69, 68, 67, 66, 65, 64, 37, 36, 35, 34, 33, 32, 20, 19, 18, 17, 16, 11, 10, 9, 8, 6, 5, 4, 3, 2, 1;
;Puerto 22: 64, 1, 0, 0, 64, 2, 1024, 0, 64, 2, 512, 0, 64, 2, 256, 0, 64, 2, 128, 0, 64, 2, 64, 0, 64, 2, 32, 0, 64, 2, 16, 0, 64, 2, 8, 0, 64, 2, 4, 0, 64, 2, 2, 0, 64, 2, 1, 0, 64, 2, 3, 0, 64, 2, 5, 0, 64, 2, 6, 0, 64, 2, 7, 4, 64, 2, 9, 0, 64, 2, 10, 0, 64, 2, 11, 0, 64, 2, 12, 4, 64, 2, 13, 4, 64, 2, 14, 4, 64, 2, 15, 4, 64, 2, 17, 0, 64, 2, 18, 0, 64, 2, 19, 0, 64, 2, 20, 0, 64, 2, 21, 4, 64, 2, 22, 4, 64, 2, 23, 4, 64, 2, 24, 4, 64, 2, 25, 4, 64, 2, 26, 4, 64, 2, 27, 4, 64, 2, 28, 4, 64, 2, 29, 4, 64, 2, 30, 4, 64, 2, 31, 4, 64, 2, 33, 0, 64, 2, 34, 0, 64, 2, 35, 0, 64, 2, 36, 0, 64, 2, 37, 0, 64, 2, 38, 4, 64, 2, 39, 4, 64, 2, 40, 4, 64, 2, 41, 4, 64, 2, 42, 4, 64, 2, 43, 4, 64, 2, 44, 4, 64, 2, 45, 4, 64, 2, 46, 4, 64, 2, 47, 4, 64, 2, 48, 4, 64, 2, 49, 4, 64, 2, 50, 4, 64, 2, 51, 4, 64, 2, 52, 4, 64, 2, 53, 4, 64, 2, 54, 4, 64, 2, 55, 4, 64, 2, 56, 4, 64, 2, 57, 4, 64, 2, 58, 4, 64, 2, 59, 4, 64, 2, 60, 4, 64, 2, 61, 4, 64, 2, 62, 4, 64, 2, 63, 4, 64, 2, 65, 0, 64, 2, 66, 0, 64, 2, 67, 0, 64, 2, 68, 0, 64, 2, 69, 0, 64, 2, 70, 0, 64, 2, 71, 4, 64, 2, 72, 4, 64, 2, 73, 4, 64, 2, 74, 4, 64, 2, 75, 4, 64, 2, 76, 4, 64, 2, 77, 4, 64, 2, 78, 4, 64, 2, 79, 4, 64, 2, 80, 4, 64, 2, 81, 4, 64, 2, 82, 4, 64, 2, 83, 4, 64, 2, 84, 4, 64, 2, 85, 4, 64, 2, 86, 4, 64, 2, 87, 4, 64, 2, 88, 4, 64, 2, 89, 4, 64, 2, 90, 4, 64, 2, 91, 4, 64, 2, 92, 4, 64, 2, 93, 4, 64, 2, 94, 4, 64, 2, 95, 4, 64, 2, 96, 4, 64, 2, 97, 4, 64, 2, 98, 4, 64, 2, 99, 4, 64, 2, 100, 4, 64, 2, 101, 4, 64, 2, 102, 4, 64, 2, 103, 4, 64, 2, 104, 4, 64, 2, 105, 4, 64, 2, 106, 4, 64, 2, 107, 4, 64, 2, 108, 4, 64, 2, 109, 4, 64, 2, 110, 4, 64, 2, 111, 4, 64, 2, 112, 4, 64, 2, 113, 4, 64, 2, 114, 4, 64, 2, 115, 4, 64, 2, 116, 4, 64, 2, 117, 4, 64, 2, 118, 4, 64, 2, 119, 4, 64, 2, 120, 4, 64, 2, 121, 4, 64, 2, 122, 4, 64, 2, 123, 4, 64, 2, 124, 4, 64, 2, 125, 4, 64, 2, 126, 4, 64, 2, 127, 4, 64, 2, 2048, 0, 64, 2, 1025, 0, 64, 2, 1026, 0, 64, 2, 1027, 0, 64, 2, 1028, 0, 64, 2, 1029, 0, 64, 2, 1030, 0, 64, 2, 1031, 0, 64, 2, 1032, 0, 64, 2, 1033, 0, 64, 2, 1034, 4, 64, 2, 1035, 4, 64, 2, 1036, 4, 64, 2, 1037, 4, 64, 2, 1038, 4, 64, 2, 1039, 4, 64, 2, 1040, 4, 64, 2, 1041, 4, 64, 2, 1042, 4, 64, 2, 1043, 4, 64, 2, 1044, 4, 64, 2, 1045, 4, 64, 2, 1046, 4, 64, 2, 1047, 4, 64, 2, 1048, 4, 64, 2, 1049, 4, 64, 2, 1050, 4, 64, 2, 1051, 4, 64, 2, 1052, 4, 64, 2, 1053, 4, 64, 2, 1054, 4, 64, 2, 1055, 4, 64, 2, 1056, 4, 64, 2, 1057, 4, 64, 2, 1058, 4, 64, 2, 1059, 4, 64, 2, 1060, 4, 64, 2, 1061, 4, 64, 2, 1062, 4, 64, 2, 1063, 4, 64, 2, 1064, 4, 64, 2, 1065, 4, 64, 2, 1066, 4, 64, 2, 1067, 4, 64, 2, 1068, 4, 64, 2, 1069, 4, 64, 2, 1070, 4, 64, 2, 1071, 4, 64, 2, 1072, 4, 64, 2, 1073, 4, 64, 2, 1074, 4, 64, 2, 1075, 4, 64, 2, 1076, 4, 64, 2, 1077, 4, 64, 2, 1078, 4, 64, 2, 1079, 4, 64, 2, 1080, 4, 64, 2, 1081, 4, 64, 2, 1082, 4, 64, 2, 1083, 4, 64, 2, 1084, 4, 64, 2, 1085, 4, 64, 2, 1086, 4, 64, 2, 1087, 4, 64, 2, 1088, 4, 64, 2, 1089, 4, 64, 2, 1090, 4, 64, 2, 1091, 4, 64, 2, 1092, 4, 64, 2, 1093, 4, 64, 2, 1094, 4, 64, 2, 1095, 4, 64, 2, 1096, 4, 64, 2, 1097, 4, 64, 2, 1098, 4, 64, 2, 1099, 4, 64, 2, 1100, 4, 64, 2, 1101, 4, 64, 2, 1102, 4, 64, 2, 1103, 4, 64, 2, 1104, 4, 64, 2, 1105, 4, 64, 2, 1106, 4, 64, 2, 1107, 4, 64, 2, 1108, 4, 64, 2, 1109, 4, 64, 2, 1110, 4, 64, 2, 1111, 4, 64, 2, 1112, 4, 64, 2, 1113, 4, 64, 2, 1114, 4, 64, 2, 1115, 4, 64, 2, 1116, 4, 64, 2, 1117, 4, 64, 2, 1118, 4, 64, 2, 1119, 4, 64, 2, 1120, 4, 64, 2, 1121, 4, 64, 2, 1122, 4, 64, 2, 1123, 4, 64, 2, 1124, 4, 64, 2, 1125, 4, 64, 2, 1126, 4, 64, 2, 1127, 4, 64, 2, 1128, 4, 64, 2, 1129, 4, 64, 2, 1130, 4, 64, 2, 1131, 4, 64, 2, 1132, 4, 64, 2, 1133, 4, 64, 2, 1134, 4, 64, 2, 1135, 4, 64, 2, 1136, 4, 64, 2, 1137, 4, 64, 2, 1138, 4, 64, 2, 1139, 4, 64, 2, 1140, 4, 64, 2, 1141, 4, 64, 2, 1142, 4, 64, 5, 1, 0, 64, 255, 0
;Puerto 21: 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 16, 17, 18, 19, 20, 32, 33, 34, 35, 36, 37, 64, 65, 66, 67, 68, 69, 70, 128, 256, 512, 1024, 1025, 1026, 1027, 1028, 1029, 1030, 1031, 1032, 1033, 2048
;Puerto 22: 64, 1, 0, 0, 64, 2, 1024, 0, 64, 2, 512, 0, 64, 2, 256, 0, 64, 2, 128, 0, 64, 2, 64, 0, 64, 2, 32, 0, 64, 2, 16, 0, 64, 2, 8, 0, 64, 2, 4, 0, 64, 2, 2, 0, 64, 2, 1, 0, 64, 2, 3, 0, 64, 2, 5, 0, 64, 2, 6, 0, 64, 2, 7, 4, 64, 2, 9, 0, 64, 2, 10, 0, 64, 2, 11, 0, 64, 2, 12, 4, 64, 2, 13, 4, 64, 2, 14, 4, 64, 2, 15, 4, 64, 2, 17, 0, 64, 2, 18, 0, 64, 2, 19, 0, 64, 2, 20, 0, 64, 2, 21, 4, 64, 2, 22, 4, 64, 2, 23, 4, 64, 2, 24, 4, 64, 2, 25, 4, 64, 2, 26, 4, 64, 2, 27, 4, 64, 2, 28, 4, 64, 2, 29, 4, 64, 2, 30, 4, 64, 2, 31, 4, 64, 2, 33, 0, 64, 2, 34, 0, 64, 2, 35, 0, 64, 2, 36, 0, 64, 2, 37, 0, 64, 2, 38, 4, 64, 2, 39, 4, 64, 2, 40, 4, 64, 2, 41, 4, 64, 2, 42, 4, 64, 2, 43, 4, 64, 2, 44, 4, 64, 2, 45, 4, 64, 2, 46, 4, 64, 2, 47, 4, 64, 2, 48, 4, 64, 2, 49, 4, 64, 2, 50, 4, 64, 2, 51, 4, 64, 2, 52, 4, 64, 2, 53, 4, 64, 2, 54, 4, 64, 2, 55, 4, 64, 2, 56, 4, 64, 2, 57, 4, 64, 2, 58, 4, 64, 2, 59, 4, 64, 2, 60, 4, 64, 2, 61, 4, 64, 2, 62, 4, 64, 2, 63, 4, 64, 2, 65, 0, 64, 2, 66, 0, 64, 2, 67, 0, 64, 2, 68, 0, 64, 2, 69, 0, 64, 2, 70, 0, 64, 2, 71, 4, 64, 2, 72, 4, 64, 2, 73, 4, 64, 2, 74, 4, 64, 2, 75, 4, 64, 2, 76, 4, 64, 2, 77, 4, 64, 2, 78, 4, 64, 2, 79, 4, 64, 2, 80, 4, 64, 2, 81, 4, 64, 2, 82, 4, 64, 2, 83, 4, 64, 2, 84, 4, 64, 2, 85, 4, 64, 2, 86, 4, 64, 2, 87, 4, 64, 2, 88, 4, 64, 2, 89, 4, 64, 2, 90, 4, 64, 2, 91, 4, 64, 2, 92, 4, 64, 2, 93, 4, 64, 2, 94, 4, 64, 2, 95, 4, 64, 2, 96, 4, 64, 2, 97, 4, 64, 2, 98, 4, 64, 2, 99, 4, 64, 2, 100, 4, 64, 2, 101, 4, 64, 2, 102, 4, 64, 2, 103, 4, 64, 2, 104, 4, 64, 2, 105, 4, 64, 2, 106, 4, 64, 2, 107, 4, 64, 2, 108, 4, 64, 2, 109, 4, 64, 2, 110, 4, 64, 2, 111, 4, 64, 2, 112, 4, 64, 2, 113, 4, 64, 2, 114, 4, 64, 2, 115, 4, 64, 2, 116, 4, 64, 2, 117, 4, 64, 2, 118, 4, 64, 2, 119, 4, 64, 2, 120, 4, 64, 2, 121, 4, 64, 2, 122, 4, 64, 2, 123, 4, 64, 2, 124, 4, 64, 2, 125, 4, 64, 2, 126, 4, 64, 2, 127, 4, 64, 2, 2048, 0, 64, 2, 1025, 0, 64, 2, 1026, 0, 64, 2, 1027, 0, 64, 2, 1028, 0, 64, 2, 1029, 0, 64, 2, 1030, 0, 64, 2, 1031, 0, 64, 2, 1032, 0, 64, 2, 1033, 0, 64, 2, 1034, 4, 64, 2, 1035, 4, 64, 2, 1036, 4, 64, 2, 1037, 4, 64, 2, 1038, 4, 64, 2, 1039, 4, 64, 2, 1040, 4, 64, 2, 1041, 4, 64, 2, 1042, 4, 64, 2, 1043, 4, 64, 2, 1044, 4, 64, 2, 1045, 4, 64, 2, 1046, 4, 64, 2, 1047, 4, 64, 2, 1048, 4, 64, 2, 1049, 4, 64, 2, 1050, 4, 64, 2, 1051, 4, 64, 2, 1052, 4, 64, 2, 1053, 4, 64, 2, 1054, 4, 64, 2, 1055, 4, 64, 2, 1056, 4, 64, 2, 1057, 4, 64, 2, 1058, 4, 64, 2, 1059, 4, 64, 2, 1060, 4, 64, 2, 1061, 4, 64, 2, 1062, 4, 64, 2, 1063, 4, 64, 2, 1064, 4, 64, 2, 1065, 4, 64, 2, 1066, 4, 64, 2, 1067, 4, 64, 2, 1068, 4, 64, 2, 1069, 4, 64, 2, 1070, 4, 64, 2, 1071, 4, 64, 2, 1072, 4, 64, 2, 1073, 4, 64, 2, 1074, 4, 64, 2, 1075, 4, 64, 2, 1076, 4, 64, 2, 1077, 4, 64, 2, 1078, 4, 64, 2, 1079, 4, 64, 2, 1080, 4, 64, 2, 1081, 4, 64, 2, 1082, 4, 64, 2, 1083, 4, 64, 2, 1084, 4, 64, 2, 1085, 4, 64, 2, 1086, 4, 64, 2, 1087, 4, 64, 2, 1088, 4, 64, 2, 1089, 4, 64, 2, 1090, 4, 64, 2, 1091, 4, 64, 2, 1092, 4, 64, 2, 1093, 4, 64, 2, 1094, 4, 64, 2, 1095, 4, 64, 2, 1096, 4, 64, 2, 1097, 4, 64, 2, 1098, 4, 64, 2, 1099, 4, 64, 2, 1100, 4, 64, 2, 1101, 4, 64, 2, 1102, 4, 64, 2, 1103, 4, 64, 2, 1104, 4, 64, 2, 1105, 4, 64, 2, 1106, 4, 64, 2, 1107, 4, 64, 2, 1108, 4, 64, 2, 1109, 4, 64, 2, 1110, 4, 64, 2, 1111, 4, 64, 2, 1112, 4, 64, 2, 1113, 4, 64, 2, 1114, 4, 64, 2, 1115, 4, 64, 2, 1116, 4, 64, 2, 1117, 4, 64, 2, 1118, 4, 64, 2, 1119, 4, 64, 2, 1120, 4, 64, 2, 1121, 4, 64, 2, 1122, 4, 64, 2, 1123, 4, 64, 2, 1124, 4, 64, 2, 1125, 4, 64, 2, 1126, 4, 64, 2, 1127, 4, 64, 2, 1128, 4, 64, 2, 1129, 4, 64, 2, 1130, 4, 64, 2, 1131, 4, 64, 2, 1132, 4, 64, 2, 1133, 4, 64, 2, 1134, 4, 64, 2, 1135, 4, 64, 2, 1136, 4, 64, 2, 1137, 4, 64, 2, 1138, 4, 64, 2, 1139, 4, 64, 2, 1140, 4, 64, 2, 1141, 4, 64, 2, 1142, 4, 64, 5, 0, 0, 64, 255, 0
;20:1,0,2,1024,2,512,2,256,2,128,2,64,2,32,2,16,2,8,2,4,2,2,2,1,2,3,2,5,2,6,2,7,2,9,2,10,2,11,2,12,2,13,2,14,2,15,2,17,2,18,2,19,2,20,2,21,2,22,2,23,2,24,2,25,2,26,2,27,2,28,2,29,2,30,2,31,2,33,2,34,2,35,2,36,2,37,2,38,2,39,2,40,2,41,2,42,2,43,2,44,2,45,2,46,2,47,2,48,2,49,2,50,2,51,2,52,2,53,2,54,2,55,2,56,2,57,2,58,2,59,2,60,2,61,2,62,2,63,2,65,2,66,2,67,2,68,2,69,2,70,2,71,2,72,2,73,2,74,2,75,2,76,2,77,2,78,2,79,2,80,2,81,2,82,2,83,2,84,2,85,2,86,2,87,2,88,2,89,2,90,2,91,2,92,2,93,2,94,2,95,2,96,2,97,2,98,2,99,2,100,2,101,2,102,2,103,2,104,2,105,2,106,2,107,2,108,2,109,2,110,2,111,2,112,2,113,2,114,2,115,2,116,2,117,2,118,2,119,2,120,2,121,2,122,2,123,2,124,2,125,2,126,2,127,2,2048,2,1025,2,1026,2,1027,2,1028,2,1029,2,1030,2,1031,2,1032,2,1033,2,1034,2,1035,2,1036,2,1037,2,1038,2,1039,2,1040,2,1041,2,1042,2,1043,2,1044,2,1045,2,1046,2,1047,2,1048,2,1049,2,1050,2,1051,2,1052,2,1053,2,1054,2,1055,2,1056,2,1057,2,1058,2,1059,2,1060,2,1061,2,1062,2,1063,2,1064,2,1065,2,1066,2,1067,2,1068,2,1069,2,1070,2,1071,2,1072,2,1073,2,1074,2,1075,2,1076,2,1077,2,1078,2,1079,2,1080,2,1081,2,1082,2,1083,2,1084,2,1085,2,1086,2,1087,2,1088,2,1089,2,1090,2,1091,2,1092,2,1093,2,1094,2,1095,2,1096,2,1097,2,1098,2,1099,2,1100,2,1101,2,1102,2,1103,2,1104,2,1105,2,1106,2,1107,2,1108,2,1109,2,1110,2,1111,2,1112,2,1113,2,1114,2,1115,2,1116,2,1117,2,1118,2,1119,2,1120,2,1121,2,1122,2,1123,2,1124,2,1125,2,1126,2,1127,2,1128,2,1129,2,1130,2,1131,2,1132,2,1133,2,1134,2,1135,2,1136,2,1137,2,1138,2,1139,2,1140,2,1141,2,1142,5,0,255
;Puerto 21: 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 16, 17, 18, 19, 20, 32, 33, 34, 35, 36, 37, 64, 65, 66, 67, 68, 69, 70, 128, 256, 512, 1024, 1025, 1026, 1027, 1028, 1029, 1030, 1031, 1032, 1033, 2048
;Puerto 22: 64, 1, 0, 0, 64, 2, 1024, 0, 64, 2, 512, 0, 64, 2, 256, 0, 64, 2, 128, 0, 64, 2, 64, 0, 64, 2, 32, 0, 64, 2, 16, 0, 64, 2, 8, 0, 64, 2, 4, 0, 64, 2, 2, 0, 64, 2, 1, 0, 64, 2, 3, 0, 64, 2, 5, 0, 64, 2, 6, 0, 64, 2, 7, 4, 64, 2, 9, 0, 64, 2, 10, 0, 64, 2, 11, 0, 64, 2, 12, 4, 64, 2, 13, 4, 64, 2, 14, 4, 64, 2, 15, 4, 64, 2, 17, 0, 64, 2, 18, 0, 64, 2, 19, 0, 64, 2, 20, 0, 64, 2, 21, 4, 64, 2, 22, 4, 64, 2, 23, 4, 64, 2, 24, 4, 64, 2, 25, 4, 64, 2, 26, 4, 64, 2, 27, 4, 64, 2, 28, 4, 64, 2, 29, 4, 64, 2, 30, 4, 64, 2, 31, 4, 64, 2, 33, 0, 64, 2, 34, 0, 64, 2, 35, 0, 64, 2, 36, 0, 64, 2, 37, 0, 64, 2, 38, 4, 64, 2, 39, 4, 64, 2, 40, 4, 64, 2, 41, 4, 64, 2, 42, 4, 64, 2, 43, 4, 64, 2, 44, 4, 64, 2, 45, 4, 64, 2, 46, 4, 64, 2, 47, 4, 64, 2, 48, 4, 64, 2, 49, 4, 64, 2, 50, 4, 64, 2, 51, 4, 64, 2, 52, 4, 64, 2, 53, 4, 64, 2, 54, 4, 64, 2, 55, 4, 64, 2, 56, 4, 64, 2, 57, 4, 64, 2, 58, 4, 64, 2, 59, 4, 64, 2, 60, 4, 64, 2, 61, 4, 64, 2, 62, 4, 64, 2, 63, 4, 64, 2, 65, 0, 64, 2, 66, 0, 64, 2, 67, 0, 64, 2, 68, 0, 64, 2, 69, 0, 64, 2, 70, 0, 64, 2, 71, 4, 64, 2, 72, 4, 64, 2, 73, 4, 64, 2, 74, 4, 64, 2, 75, 4, 64, 2, 76, 4, 64, 2, 77, 4, 64, 2, 78, 4, 64, 2, 79, 4, 64, 2, 80, 4, 64, 2, 81, 4, 64, 2, 82, 4, 64, 2, 83, 4, 64, 2, 84, 4, 64, 2, 85, 4, 64, 2, 86, 4, 64, 2, 87, 4, 64, 2, 88, 4, 64, 2, 89, 4, 64, 2, 90, 4, 64, 2, 91, 4, 64, 2, 92, 4, 64, 2, 93, 4, 64, 2, 94, 4, 64, 2, 95, 4, 64, 2, 96, 4, 64, 2, 97, 4, 64, 2, 98, 4, 64, 2, 99, 4, 64, 2, 100, 4, 64, 2, 101, 4, 64, 2, 102, 4, 64, 2, 103, 4, 64, 2, 104, 4, 64, 2, 105, 4, 64, 2, 106, 4, 64, 2, 107, 4, 64, 2, 108, 4, 64, 2, 109, 4, 64, 2, 110, 4, 64, 2, 111, 4, 64, 2, 112, 4, 64, 2, 113, 4, 64, 2, 114, 4, 64, 2, 115, 4, 64, 2, 116, 4, 64, 2, 117, 4, 64, 2, 118, 4, 64, 2, 119, 4, 64, 2, 120, 4, 64, 2, 121, 4, 64, 2, 122, 4, 64, 2, 123, 4, 64, 2, 124, 4, 64, 2, 125, 4, 64, 2, 126, 4, 64, 2, 127, 4, 64, 2, 2048, 0, 64, 2, 1025, 0, 64, 2, 1026, 0, 64, 2, 1027, 0, 64, 2, 1028, 0, 64, 2, 1029, 0, 64, 2, 1030, 0, 64, 2, 1031, 0, 64, 2, 1032, 0, 64, 2, 1033, 0, 64, 2, 1034, 4, 64, 2, 1035, 4, 64, 2, 1036, 4, 64, 2, 1037, 4, 64, 2, 1038, 4, 64, 2, 1039, 4, 64, 2, 1040, 4, 64, 2, 1041, 4, 64, 2, 1042, 4, 64, 2, 1043, 4, 64, 2, 1044, 4, 64, 2, 1045, 4, 64, 2, 1046, 4, 64, 2, 1047, 4, 64, 2, 1048, 4, 64, 2, 1049, 4, 64, 2, 1050, 4, 64, 2, 1051, 4, 64, 2, 1052, 4, 64, 2, 1053, 4, 64, 2, 1054, 4, 64, 2, 1055, 4, 64, 2, 1056, 4, 64, 2, 1057, 4, 64, 2, 1058, 4, 64, 2, 1059, 4, 64, 2, 1060, 4, 64, 2, 1061, 4, 64, 2, 1062, 4, 64, 2, 1063, 4, 64, 2, 1064, 4, 64, 2, 1065, 4, 64, 2, 1066, 4, 64, 2, 1067, 4, 64, 2, 1068, 4, 64, 2, 1069, 4, 64, 2, 1070, 4, 64, 2, 1071, 4, 64, 2, 1072, 4, 64, 2, 1073, 4, 64, 2, 1074, 4, 64, 2, 1075, 4, 64, 2, 1076, 4, 64, 2, 1077, 4, 64, 2, 1078, 4, 64, 2, 1079, 4, 64, 2, 1080, 4, 64, 2, 1081, 4, 64, 2, 1082, 4, 64, 2, 1083, 4, 64, 2, 1084, 4, 64, 2, 1085, 4, 64, 2, 1086, 4, 64, 2, 1087, 4, 64, 2, 1088, 4, 64, 2, 1089, 4, 64, 2, 1090, 4, 64, 2, 1091, 4, 64, 2, 1092, 4, 64, 2, 1093, 4, 64, 2, 1094, 4, 64, 2, 1095, 4, 64, 2, 1096, 4, 64, 2, 1097, 4, 64, 2, 1098, 4, 64, 2, 1099, 4, 64, 2, 1100, 4, 64, 2, 1101, 4, 64, 2, 1102, 4, 64, 2, 1103, 4, 64, 2, 1104, 4, 64, 2, 1105, 4, 64, 2, 1106, 4, 64, 2, 1107, 4, 64, 2, 1108, 4, 64, 2, 1109, 4, 64, 2, 1110, 4, 64, 2, 1111, 4, 64, 2, 1112, 4, 64, 2, 1113, 4, 64, 2, 1114, 4, 64, 2, 1115, 4, 64, 2, 1116, 4, 64, 2, 1117, 4, 64, 2, 1118, 4, 64, 2, 1119, 4, 64, 2, 1120, 4, 64, 2, 1121, 4, 64, 2, 1122, 4, 64, 2, 1123, 4, 64, 2, 1124, 4, 64, 2, 1125, 4, 64, 2, 1126, 4, 64, 2, 1127, 4, 64, 2, 1128, 4, 64, 2, 1129, 4, 64, 2, 1130, 4, 64, 2, 1131, 4, 64, 2, 1132, 4, 64, 2, 1133, 4, 64, 2, 1134, 4, 64, 2, 1135, 4, 64, 2, 1136, 4, 64, 2, 1137, 4, 64, 2, 1138, 4, 64, 2, 1139, 4, 64, 2, 1140, 4, 64, 2, 1141, 4, 64, 2, 1142, 4, 64, 5, 0, 0, 64, 255, 0

;22: 64, 1, 1, 0, 64, 2, 1, 0, 64, 2, 2, 0, 64, 2, 3, 0, 64, 2, 4, 0, 64, 2, 5, 0, 64, 2, 6, 0, 64, 2, 7, 0, 64, 2, 8, 0, 64, 2, 9, 0, 64, 2, 10, 0, 64, 2, 11, 0, 64, 2, 12, 0, 64, 2, 13, 0, 64, 2, 14, 0, 64, 2, 15, 0, 64, 2, 16, 0, 64, 255, 0
;20:1,0,2,1,2,2,2,3,2,4,2,5,2,6,2,7,2,8,2,9,2,10,2,11,2,12,2,13,2,14,2,15,2,16,255
;22: 64, 1, 0, 0, 64, 2, 1, 0, 64, 2, 2, 0, 64, 2, 3, 0, 64, 2, 4, 0, 64, 2, 5, 0, 64, 2, 6, 0, 64, 2, 7, 0, 64, 2, 8, 0, 64, 2, 9, 0, 64, 2, 10, 0, 64, 2, 11, 0, 64, 2, 12, 4, 64, 2, 13, 4, 64, 2, 14, 4, 64, 2, 15, 4, 64, 2, 16, 4, 64, 255
;CU altura max
;20:1,0,2,11,2,10,2,8,2,20,3,1,1,2,10,2,8,2,20,3,255
;20: 1,0,2,3,2,5,2,6,2,7,2,9,2,1,2,2,3,1,1,2,3,2,5,2,6,2,7,2,9,2,1,2,2,3,255
; 21: 5, 5
; 22: 64, 1, 0, 0, 64, 2, 3, 0, 64, 2, 5, 0, 64, 2, 6, 0, 64, 2, 7, 0, 64, 2, 9, 0, 64, 2, 1, 0, 64, 2, 2, 0, 64, 3, 0, 64, 1, 1, 0, 64, 2, 3, 0, 64, 2, 5, 0, 64, 2, 6, 0, 64, 2, 7, 0, 64, 2, 9, 0, 64, 2, 1, 0, 64, 2, 2, 0, 64, 3, 0

;CU:mios

;20: 1,0,3,1,1,3,1,0,2,4,3,1,1,2,5,3,1,0,2,100,2,128,2,60,2,40,2,20,2,22,3,1,1,2,50,2,40,2,30,2,45,2,46,2,47,2,48,3,255
;21: 0,0,1,1,5,6
;22: 64,1,0,0,64,3,0,64,1,1,0,64,3,0,64,1,0,0,64,2,4,0,64,3,0,64,1,1,0,64,2,5,0,64,3,0,64,1,0,0,64,2,100,0,64,2,128,0,64,2,60,0,64,2,40,0,64,2,20,0,64,2,22,0,64,3,0,64,1,1,0,64,2,50,0,64,2,40,0,64,2,30,0,64,2,45,0,64,2,46,0,64,2,47,0,64,2,48,0,64,3,0,64,255,0
;CU: test altura

;20: 1,2,1,-1,5,-1,5,4,6,-1,244,-5,255
;21: 
;22: 64,1,2,2,64,1,-1,2,64,5,-1,2,64,5,4,2,64,6,-1,2,64,244,1,64,-5,1,64,255,0
;CU: test errores

;20: 1,0,2,100,2,200,2,50,2,30,2,150,4,1,1,2,102,2,202,2,52,2,32,2,152,4,255
;21: 530,540
;22: 64,1,0,0,64,2,100,0,64,2,200,0,64,2,50,0,64,2,30,0,64,2,150,0,64,4,0,64,1,1,0,64,2,102,0,64,2,202,0,64,2,52,0,64,2,32,0,64,2,152,0,64,4,0,64,255,0
;CU: test suma

;20: 1,0,5,1,1,1,5,1,1,0,2,4,5,1,1,1,2,5,5,1,1,0,2,100,2,128,2,60,2,40,2,20,2,22,5,1,5,0,1,1,2,50,2,40,2,30,2,45,2,46,2,47,2,48,5,0,5,1,255
;21: 4,5,128,100,60,40,22,20,20,22,40,60,100,128,30,40,45,46,47,48,50,50,48,47,46,45,40,30
;22: 64,1,0,0,64,5,1,0,64,1,1,0,64,5,1,0,64,1,0,0,64,2,4,0,64,5,1,0,64,1,1,0,64,2,5,0,64,5,1,0,64,1,0,0,64,2,100,0,64,2,128,0,64,2,60,0,64,2,40,0,64,2,20,0,64,2,22,0,64,5,1,0,64,5,0,0,64,1,1,0,64,2,50,0,64,2,40,0,64,2,30,0,64,2,45,0,64,2,46,0,64,2,47,0,64,2,48,0,64,5,0,0,64,5,1,0,64,255,0
;CU: test imprimir

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

