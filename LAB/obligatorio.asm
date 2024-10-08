;códigos de sálida
CODIGO_EXITO EQU 0
CODIGO_COMANDO_INVALIDO EQU 1
CODIGO_PARAMETRO_INVALIDO EQU 2
CODIGO_ESCRITURA_INVALIDA EQU 4
CODIGO_NODO_EXISTENTE EQU 8
;cte obligatoria
AREA_MEMORIA EQU 2048
;cts propias
VACIO EQU 0x8000
AREA_MEMORIA_BYTES EQU 2048 * 2
CANT_NODOS_DINAMICOS EQU 682 ; no se cuenta el 0, hay 682
;puertos
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
	CMP AX,VACIO
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
		
		MOV BX, AX
		MOV AX,6
		MUL BX ; mul ax=6*ax
		
		JMP imprimir_memoria_din_est

;implementaciones de CU's
agregarNodoEstatico PROC
	PUSH AX ;ES:[BP + 4],num
	PUSH SI ;ES:[BP + 2],pos
	PUSH BP
	MOV BP,SP

	MOV SI,[BP+2] ;desplz 
	MOV AX,[BP+4] ;nro a insertar

	CMP ES:[SI],VACIO ;AREA_DE_MEMORIA[pos] == VACIO	
		JE	insertar
	CMP SI, AREA_MEMORIA_BYTES; pos >2048
		JG error_excede
	CMP AX, ES:[SI]; AREA_DE_MEMORIA[nodo]>num
		JG insercion_der ;>
	CMP AX,ES:[SI] ;AREA_DE_MEMORIA[nodo]<num
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
	insercion_der:;paso recursivo
		SHL SI,1 ;pos=2pos+2
		ADD SI,4
		CALL agregarNodoEstatico
		JMP finalizarRecursion
	insercion_izq:;paso recursivo
		SHL SI,1 ;pos=2pos+1
		ADD SI,2
		CALL agregarNodoEstatico
		JMP finalizarRecursion
	insertar:;PB
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
	PUSH AX ;ES:[BP + 4],num
	PUSH SI ;ES:[BP + 2],pos
	PUSH BP
	MOV BP,SP

	MOV SI,[BP+2] ;desplz 
	MOV AX,[BP+4] ;nro a insertar

	CMP [nodoDinamico],681; nodo maximo 682, no se cuenta el 0
		JNL error_excede_din
	CMP ES:[SI],VACIO ;AREA_DE_MEMORIA[pos] == VACIO	
		JE	insertarDinamico
	CMP SI, AREA_MEMORIA_BYTES ;pos > 2048
		JG error_excede_din
	CMP AX, ES:[SI]; AREA_DE_MEMORIA[nodo]<num
		JG insercion_der_din ;>
	CMP AX,ES:[SI] ;AREA_DE_MEMORIA[nodo]<num
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
	insercion_der_din:;(num > AREA_DE_MEMORIA[pos])
		CMP ES:[SI+4], VACIO ;AREA_DE_MEMORIA[pos+2] != VACIO
			JE elseDer
		CMP ES:[SI+4], CANT_NODOS_DINAMICOS ;pos> 2048/3
			JG finalizarRecursionDinamico
		; agregarNodoDinamico(num, 3*AREA_DE_MEMORIA[pos+2]);
		PUSH AX
		MOV AX,6
		MOV SI, ES:[SI+4];indice del nodo 
		MUL SI
		MOV SI, AX
		POP AX

		CALL agregarNodoDinamico
		JMP finalizarRecursionDinamico
		elseDer: 
			ADD SI,4
			CALL agregarNodoDinamico
			JMP finalizarRecursionDinamico

	insercion_izq_din:;(num > AREA_DE_MEMORIA[pos])
		CMP ES:[SI+2], VACIO;AREA_DE_MEMORIA[pos+2] != VACIO
			JE elseIzq

		; agregarNodoDinamico(num, 3*AREA_DE_MEMORIA[pos+1]);
		PUSH AX
		MOV AX,6
		MOV SI, ES:[SI+2] ;indice del nodo
		MUL SI
		MOV SI, AX
		POP AX

		CALL agregarNodoDinamico
		JMP finalizarRecursionDinamico
		elseIzq:
			ADD SI,2
			CALL agregarNodoDinamico
			JMP finalizarRecursionDinamico
	insertarDinamico:;PB pos!=0
		CMP SI,0 ; inserta el primer nodo
			JE insertarPrimero
		
		INC word ptr DS:[nodoDinamico] ; nodoDinamico++; 
		MOV BX,DS:[nodoDinamico]
		MOV word ptr ES:[SI],BX ; AREA_DE_MEMORIA[pos] = nodoDinamico;
		 
		; prepara SI, en posicion
		PUSH AX
		MOV AX,6
		MUL BX
		MOV SI, AX  ;3*pos = nodoDinamico
		POP AX

		MOV	ES:[SI],AX ;; AREA_DE_MEMORIA[3*nodoDinamico] = num;
		MOV AX,CODIGO_EXITO  
		OUT PUERTO_LOG,AX
		JMP finalizarRecursionDinamico

	insertarPrimero:;PB pos=0
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
	PUSH SI ;pos
	PUSH DX ;alt izq
	PUSH BX ;alt der
    PUSH BP
    MOV BP, SP

    MOV SI, [BP + 6]; para contexto

	CMP SI,AREA_MEMORIA_BYTES ;pos<2048/3	
		JG	fin_altura_dinamico
    CMP ES:[SI], VACIO ; AREA_DE_MEMORIA[pos] = VACIO
    	JE fin_altura_dinamico

    ; Calcular alturas de las subárboles izquierdo y derecho
   	MOV BX, [BP+2]
	INC BX ;altDerecha
	
	MOV SI,ES:[SI+4] 

	CMP SI,VACIO;pos != VACIO
		JE salto_ejec_der_altura
	
	PUSH AX
	MOV AX,6
	MUL SI
	MOV SI,AX;3*pos
	POP AX

    CALL calcular_altura_dinamico

	salto_ejec_der_altura:

	MOV SI, [BP+6] ;conservar contexto

	MOV SI,ES:[SI+2] 

	CMP SI,VACIO;pos != VACIO
		JE salto_ejec_izq_altura
	;comentar aca
	PUSH AX
	MOV AX,6
	MUL SI
	MOV SI,AX
	POP AX

	MOV DX, [BP+4]
  	INC DX ;altIzq

    CALL calcular_altura_dinamico

	salto_ejec_izq_altura:
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
	PUSH SI ;pos
	PUSH DX ;alt izq
	PUSH BX ;alt der
    PUSH BP
    MOV BP, SP
    MOV SI, [BP + 6]

	CMP SI,AREA_MEMORIA_BYTES ;pos > 2048	
		JG	fin_altura_estatico
    CMP ES:[SI], VACIO ;AREA_DE_MEMORIA[pos] != VACIO
    	JE fin_altura_estatico
    ; Calcular alturas de las subárboles izquierdo y derecho
	SHL SI,1
	ADD SI,4

	MOV BX, [BP+2];retorna contexto
	INC BX; incrementa altura der
    CALL calcular_altura_estatico

	MOV SI,[BP+6];retorna contexto

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

	CMP SI,AREA_MEMORIA_BYTES;pos>2048/3		
		JG	fin_suma_dinamica

	CMP ES:[SI], VACIO;AREA_DE_MEMORIA[pos] != VACIO
		JE fin_suma_dinamica

	ADD AX,ES:[SI];suma += AREA_DE_MEMORIA[pos]

	MOV SI, ES:[SI+4] ;pos = AREA_DE_MEMORIA[pos+2]
	CMP SI,VACIO ;AREA_DE_MEMORIA[pos] != VACIO
		JE salto_ejec_der_suma
	PUSH AX
	MOV AX,6
	MUL SI
	MOV SI,AX
	POP AX

	CALL calcular_suma_dinamico

	salto_ejec_der_suma:

	MOV SI, [BP+2] ;retoma contexto
	
	MOV SI, ES:[SI+2] ;pos = AREA_DE_MEMORIA[pos+1]

	CMP SI,VACIO;AREA_DE_MEMORIA[pos] != VACIO
		JE salto_ejec_izq_suma

	PUSH AX
	MOV AX,6
	MUL SI
	MOV SI,AX
	POP AX

	CALL calcular_suma_dinamico
	
	salto_ejec_izq_suma:

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

	CMP SI,AREA_MEMORIA_BYTES ;pos>2048	
		JG	fin_suma_estatica
	CMP ES:[SI], VACIO ;AREA_DE_MEMORIA[nodo] == VACIO
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

	CMP ES:[SI],VACIO	
		JE	finalizar_recursion_imprimir_dinamico
	
	CMP AX, 1 ; mayor a menor
		JE imprimir_mayor_a_menor_dinamico ;>
	CMP AX,0 ;menor a mayor
		JE imprimir_menor_a_mayor_dinamico ;<

	imprimir_menor_a_mayor_dinamico:

		MOV SI, ES:[SI+2] 
		CMP SI,VACIO;pos != VACIO
			JE salto_ejec_izq_imprimir_menor
		PUSH AX
		MOV AX,6
		MUL SI
		MOV SI,AX
		POP AX

		CALL imprimir_arbol_dinamico;imprimirArbolDinamico(3*AREA_DE_MEMORIA[pos+1],orden);
		salto_ejec_izq_imprimir_menor:
		PUSH AX
		MOV SI, [BP+2];sigue del índice con la ejecución del stack correspondiente
		MOV AX, ES:[SI]
		OUT PUERTO_SALIDA,AX
		POP AX
		
		MOV SI, ES:[SI+4] 
		CMP SI,VACIO;pos != VACIO
			JE salto_ejec_der_imprimir_menor

		PUSH AX
		MOV AX,6
		MUL SI
		MOV SI,AX
		POP AX

		CALL imprimir_arbol_dinamico;imprimirArbolDinamico(3*AREA_DE_MEMORIA[pos+2],orden);
		salto_ejec_der_imprimir_menor:

		JMP finalizar_recursion_imprimir_dinamico
	imprimir_mayor_a_menor_dinamico:
		
		MOV SI, ES:[SI+4] 
		CMP SI,VACIO;pos != VACIO
			JE salto_ejec_der_imprimir_mayor

		PUSH AX
		MOV AX,6
		MUL SI
		MOV SI,AX
		POP AX
		
		CALL imprimir_arbol_dinamico;imprimirArbolDinamico(3*AREA_DE_MEMORIA[pos+2],orden);
		salto_ejec_der_imprimir_mayor:
		PUSH AX
		MOV SI, [BP+2] ;sigue del índice con la ejecución del stack correspondiente
		MOV AX, ES:[SI]
		OUT PUERTO_SALIDA,AX
		POP AX

		MOV SI, ES:[SI+2] 
		CMP SI,VACIO;pos != VACIO
			JE salto_ejec_izq_imprimir_mayor

		PUSH AX
		MOV AX,6
		MUL SI
		MOV SI,AX
		POP AX

		CALL imprimir_arbol_dinamico;imprimirArbolDinamico(3*AREA_DE_MEMORIA[pos+1],orden);
	salto_ejec_izq_imprimir_mayor:
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
	CMP ES:[SI],VACIO	
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
	CMP SI,AX; pos<=N o pos<=3*N, se controla antes q N<=2048 o N<=682 segun modo
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
	MOV ES:[SI],VACIO
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
20:1,1,2, 1, 2, 2, 2, 3, 2, 4, 2, 5, 2, 6, 2, 7, 2, 8,2,7, 2, 9, 2, 10, 2, 11, 2, 12, 2, 13, 2, 14, 2, 15, 2, 16, 2, 17, 2, 18, 2, 19, 2, 20, 2, 21, 2, 22, 2, 23, 2, 24, 2, 25, 2, 26, 2, 27, 2, 28, 2, 29, 2, 30, 2, 31, 2, 32, 2, 33, 2, 34, 2, 35, 2, 36, 2, 37, 2, 38, 2, 39, 2, 40, 2, 41, 2, 42, 2, 43, 2, 44, 2, 45, 2, 46, 2, 47, 2, 48, 2, 49, 2, 50, 2, 51, 2, 52, 2, 53, 2, 54, 2, 55, 2, 56, 2, 57, 2, 58, 2, 59, 2, 60, 2, 61, 2, 62, 2, 63, 2, 64, 2, 65, 2, 66, 2, 67, 2, 68, 2, 69, 2, 70, 2, 71, 2, 72, 2, 73, 2, 74, 2, 75, 2, 76, 2, 77, 2, 78, 2, 79, 2, 80, 2, 81, 2, 82, 2, 83, 2, 84, 2, 85, 2, 86, 2, 87, 2, 88, 2, 89, 2, 90, 2, 91, 2, 92, 2, 93, 2, 94, 2, 95, 2, 96, 2, 97, 2, 98, 2, 99, 2, 100, 2, 101, 2, 102, 2, 103, 2, 104, 2, 105, 2, 106, 2, 107, 2, 108, 2, 109, 2, 110, 2, 111, 2, 112, 2, 113, 2, 114, 2, 115, 2, 116, 2, 117, 2, 118, 2, 119, 2, 120, 2, 121, 2, 122, 2, 123, 2, 124, 2, 125, 2, 126, 2, 127, 2, 128, 2, 129, 2, 130, 2, 131, 2, 132, 2, 133, 2, 134, 2, 135, 2, 136, 2, 137, 2, 138, 2, 139, 2, 140, 2, 141, 2, 142, 2, 143, 2, 144, 2, 145, 2, 146, 2, 147, 2, 148, 2, 149, 2, 150, 2, 151, 2, 152, 2, 153, 2, 154, 2, 155, 2, 156, 2, 157, 2, 158, 2, 159, 2, 160, 2, 161, 2, 162, 2, 163, 2, 164, 2, 165, 2, 166, 2, 167, 2, 168, 2, 169, 2, 170, 2, 171, 2, 172, 2, 173, 2, 174, 2, 175, 2, 176, 2, 177, 2, 178, 2, 179, 2, 180, 2, 181, 2, 182, 2, 183, 2, 184, 2, 185, 2, 186, 2, 187, 2, 188, 2, 189, 2, 190, 2, 191, 2, 192, 2, 193, 2, 194, 2, 195, 2, 196, 2, 197, 2, 198, 2, 199, 2, 200, 2, 201, 2, 202, 2, 203, 2, 204, 2, 205, 2, 206, 2, 207, 2, 208, 2, 209, 2, 210, 2, 211, 2, 212, 2, 213, 2, 214, 2, 215, 2, 216, 2, 217, 2, 218, 2, 219, 2, 220, 2, 221, 2, 222, 2, 223, 2, 224, 2, 225, 2, 226, 2, 227, 2, 228, 2, 229, 2, 230, 2, 231, 2, 232, 2, 233, 2, 234, 2, 235, 2, 236, 2, 237, 2, 238, 2, 239, 2, 240, 2, 241, 2, 242, 2, 243, 2, 244, 2, 245, 2, 246, 2, 247, 2, 248, 2, 249, 2, 250, 2, 251, 2, 252, 2, 253, 2, 254, 2, 255, 2, 256, 2, 257, 2, 258, 2, 259, 2, 260, 2, 261, 2, 262, 2, 263, 2, 264, 2, 265, 2, 266, 2, 267, 2, 268, 2, 269, 2, 270, 2, 271, 2, 272, 2, 273, 2, 274, 2, 275, 2, 276, 2, 277, 2, 278, 2, 279, 2, 280, 2, 281, 2, 282, 2, 283, 2, 284, 2, 285, 2, 286, 2, 287, 2, 288, 2, 289, 2, 290, 2, 291, 2, 292, 2, 293, 2, 294, 2, 295, 2, 296, 2, 297, 2, 298, 2, 299, 2, 300, 2, 301, 2, 302, 2, 303, 2, 304, 2, 305, 2, 306, 2, 307, 2, 308, 2, 309, 2, 310, 2, 311, 2, 312, 2, 313, 2, 314, 2, 315, 2, 316, 2, 317, 2, 318, 2, 319, 2, 320, 2, 321, 2, 322, 2, 323, 2, 324, 2, 325, 2, 326, 2, 327, 2, 328, 2, 329, 2, 330, 2, 331, 2, 332, 2, 333, 2, 334, 2, 335, 2, 336, 2, 337, 2, 338, 2, 339, 2, 340, 2, 341, 2, 342, 2, 343, 2, 344, 2, 345, 2, 346, 2, 347, 2, 348, 2, 349, 2, 350, 2, 351, 2, 352, 2, 353, 2, 354, 2, 355, 2, 356, 2, 357, 2, 358, 2, 359, 2, 360, 2, 361, 2, 362, 2, 363, 2, 364, 2, 365, 2, 366, 2, 367, 2, 368, 2, 369, 2, 370, 2, 371, 2, 372, 2, 373, 2, 374, 2, 375, 2, 376, 2, 377, 2, 378, 2, 379, 2, 380, 2, 381, 2, 382, 2, 383, 2, 384, 2, 385, 2, 386, 2, 387, 2, 388, 2, 389, 2, 390, 2, 391, 2, 392, 2, 393, 2, 394, 2, 395, 2, 396, 2, 397, 2, 398, 2, 399, 2, 400, 2, 401, 2, 402, 2, 403, 2, 404, 2, 405, 2, 406, 2, 407, 2, 408, 2, 409, 2, 410, 2, 411, 2, 412, 2, 413, 2, 414, 2, 415, 2, 416, 2, 417, 2, 418, 2, 419, 2, 420, 2, 421, 2, 422, 2, 423, 2, 424, 2, 425, 2, 426, 2, 427, 2, 428, 2, 429, 2, 430, 2, 431, 2, 432, 2, 433, 2, 434, 2, 435, 2, 436, 2, 437, 2, 438, 2, 439, 2, 440, 2, 441, 2, 442, 2, 443, 2, 444, 2, 445, 2, 446, 2, 447, 2, 448, 2, 449, 2, 450, 2, 451, 2, 452, 2, 453, 2, 454, 2, 455, 2, 456, 2, 457, 2, 458, 2, 459, 2, 460, 2, 461, 2, 462, 2, 463, 2, 464, 2, 465, 2, 466, 2, 467, 2, 468, 2, 469, 2, 470, 2, 471, 2, 472, 2, 473, 2, 474, 2, 475, 2, 476, 2, 477, 2, 478, 2, 479, 2, 480, 2, 481, 2, 482, 2, 483, 2, 484, 2, 485, 2, 486, 2, 487, 2, 488, 2, 489, 2, 490, 2, 491, 2, 492, 2, 493, 2, 494, 2, 495, 2, 496, 2, 497, 2, 498, 2, 499, 2, 500, 2, 501, 2, 502, 2, 503, 2, 504, 2, 505,2, 505, 2, 506, 2, 507, 2, 508, 2, 509, 2, 510, 2, 511, 2, 512, 2, 513, 2, 514, 2, 515, 2, 516, 2, 517, 2, 518, 2, 519, 2, 520, 2, 521, 2, 522, 2, 523, 2, 524, 2, 525, 2, 526, 2, 527, 2, 528, 2, 529, 2, 530, 2, 531, 2, 532, 2, 533, 2, 534, 2, 535, 2, 536, 2, 537, 2, 538, 2, 539, 2, 540, 2, 541, 2, 542, 2, 543, 2, 544, 2, 545, 2, 546, 2, 547, 2, 548, 2, 549, 2, 550, 2, 551, 2, 552, 2, 553, 2, 554, 2, 555, 2, 556, 2, 557, 2, 558, 2, 559, 2, 560, 2, 561, 2, 562, 2, 563, 2, 564, 2, 565, 2, 566, 2, 567, 2, 568, 2, 569, 2, 570, 2, 571, 2, 572, 2, 573, 2, 574, 2, 575, 2, 576, 2, 577, 2, 578, 2, 579, 2, 580, 2, 581, 2, 582, 2, 583, 2, 584, 2, 585, 2, 586, 2, 587, 2, 588, 2, 589, 2, 590, 2, 591, 2, 592, 2, 593, 2, 594, 2, 595, 2, 596, 2, 597, 2, 598, 2, 599, 2, 600, 2, 601, 2, 602, 2, 603, 2, 604, 2, 605, 2, 606, 2, 607, 2, 608, 2, 609, 2, 610, 2, 611, 2, 612, 2, 613, 2, 614, 2, 615, 2, 616, 2, 617, 2, 618, 2, 619, 2, 620, 2, 621, 2, 622, 2, 623, 2, 624, 2, 625, 2, 626, 2, 627, 2, 628, 2, 629, 2, 630, 2, 631, 2, 632, 2, 633, 2, 634, 2, 635, 2, 636, 2, 637, 2, 638, 2, 639, 2, 640, 2, 641, 2, 642, 2, 643, 2, 644, 2, 645, 2, 646, 2, 647, 2, 648, 2, 649, 2, 650, 2, 651, 2, 652, 2, 653, 2, 654, 2, 655, 2, 656, 2, 657, 2, 658, 2, 659, 2, 660, 2, 661, 2, 662, 2, 663, 2, 664, 2, 665, 2, 666, 2, 667, 2, 668, 2, 669, 2, 670, 2, 671, 2, 672, 2, 673, 2, 674, 2, 675, 2, 676, 2, 677, 2, 678, 2, 679, 2, 680, 2, 681, 2, 682, 2, 683,2,684,3,5,1,255
;20:1,0,2,12,2,11,2,10,2,9,2,8,2,7,2,6,2,5,2,4,2,3,2,2,2,1,2,0,2,1,2,3,3,255
;20:1,0,2,1024,2,512,2,256,2,128,2,64,2,32,2,16,2,8,2,4,2,2,2,1,2,3,2,5,2,6,2,7,2,9,2,10,2,11,2,12,2,13,2,14,2,15,2,17,2,18,2,19,2,20,2,21,2,22,2,23,2,24,2,25,2,26,2,27,2,28,2,29,2,30,2,31,2,33,2,34,2,35,2,36,2,37,2,38,2,39,2,40,2,41,2,42,2,43,2,44,2,45,2,46,2,47,2,48,2,49,2,50,2,51,2,52,2,53,2,54,2,55,2,56,2,57,2,58,2,59,2,60,2,61,2,62,2,63,2,65,2,66,2,67,2,68,2,69,2,70,2,71,2,72,2,73,2,74,2,75,2,76,2,77,2,78,2,79,2,80,2,81,2,82,2,83,2,84,2,85,2,86,2,87,2,88,2,89,2,90,2,91,2,92,2,93,2,94,2,95,2,96,2,97,2,98,2,99,2,100,2,101,2,102,2,103,2,104,2,105,2,106,2,107,2,108,2,109,2,110,2,111,2,112,2,113,2,114,2,115,2,116,2,117,2,118,2,119,2,120,2,121,2,122,2,123,2,124,2,125,2,126,2,127,2,2048,2,1025,2,1026,2,1027,2,1028,2,1029,2,1030,2,1031,2,1032,2,1033,2,1034,2,1035,2,1036,2,1037,2,1038,2,1039,2,1040,2,1041,2,1042,2,1043,2,1044,2,1045,2,1046,2,1047,2,1048,2,1049,2,1050,2,1051,2,1052,2,1053,2,1054,2,1055,2,1056,2,1057,2,1058,2,1059,2,1060,2,1061,2,1062,2,1063,2,1064,2,1065,2,1066,2,1067,2,1068,2,1069,2,1070,2,1071,2,1072,2,1073,2,1074,2,1075,2,1076,2,1077,2,1078,2,1079,2,1080,2,1081,2,1082,2,1083,2,1084,2,1085,2,1086,2,1087,2,1088,2,1089,2,1090,2,1091,2,1092,2,1093,2,1094,2,1095,2,1096,2,1097,2,1098,2,1099,2,1100,2,1101,2,1102,2,1103,2,1104,2,1105,2,1106,2,1107,2,1108,2,1109,2,1110,2,1111,2,1112,2,1113,2,1114,2,1115,2,1116,2,1117,2,1118,2,1119,2,1120,2,1121,2,1122,2,1123,2,1124,2,1125,2,1126,2,1127,2,1128,2,1129,2,1130,2,1131,2,1132,2,1133,2,1134,2,1135,2,1136,2,1137,2,1138,2,1139,2,1140,2,1141,2,1142,5,0,255
;20:1,1,2,1,2,2,2,3,2,4,2,5,2,6,2,7,2,8,2,9,2,10,2,11,2,12,2,13,2,14,2,15,2,16,255
;20:1,0,2,1,2,2,2,3,2,4,2,5,2,6,2,7,2,8,2,9,2,10,2,11,2,12,2,13,2,14,2,15,2,16,255
;20:1,0,2,11,2,10,2,8,2,20,3,1,1,2,10,2,8,2,20,3,255
;20: 1,0,2,3,2,5,2,6,2,7,2,9,2,1,2,2,3,1,1,2,3,2,5,2,6,2,7,2,9,2,1,2,2,3,255

;testErrores
;20: 1,2,1,-1,5,-1,5,4,6,-1,244,-5,255
;testAltura
;20: 1,0,3,1,1,3,1,0,2,4,3,1,1,2,5,3,1,0,2,100,2,128,2,60,2,40,2,20,2,22,3,1,1,2,50,2,40,2,30,2,45,2,46,2,47,2,48,3,255
;testMemoria
;20: 1,0,2,5,2,-4,2,-10,2,-80,2,60,6,0,6,1,6,10,1,1,2,5,2,-4,2,-10,2,-80,2,60,6,0,6,1,6,10,255
;testSuma
;20: 1,0,2,100,2,200,2,50,2,30,2,150,4,1,1,2,102,2,202,2,52,2,32,2,152,4,255
;testImprimir
;20: 1,0,5,1,1,1,5,1,1,0,2,4,5,1,1,1,2,5,5,1,1,0,2,100,2,128,2,60,2,40,2,20,2,22,5,1,5,0,1,1,2,50,2,40,2,30,2,45,2,46,2,47,2,48,5,0,5,1,255
;agregarNodoDinamico
;20: 1,1,2,5,2,-5,2,-4,2,8,6,10,255
;agregarNodoEstatico
;20: 1,0,2,5,2,-1,2,5,2,7,2,8,2,9,2,10,2,11,2,12,2,13,2,14,2,15,2,16,2,17,2,18,255

.interrupts ; Manejadores de interrupciones
; Ejemplo interrupcion del timer
;!INT 8 1
;  iret
;!ENDINT

