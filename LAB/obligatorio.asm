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
CANT_NODOS_DINAMICOS EQU 682
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
		SHL SI,1
		ADD SI,4
		CALL agregarNodoEstatico
		JMP finalizarRecursion
	insercion_izq:;paso recursivo
		SHL SI,1
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

	CMP ES:[SI],VACIO ;AREA_DE_MEMORIA[pos] == VACIO	
		JE	insertarDinamico
	CMP SI, AREA_MEMORIA_BYTES ;pos > 2048/3 
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
	PUSH SI
	PUSH DX ;alt izq
	PUSH BX ;alt der
    PUSH BP
    MOV BP, SP
    MOV SI, [BP + 6]

	CMP SI,AREA_MEMORIA_BYTES	
		JG	fin_altura_estatico
    CMP ES:[SI], VACIO
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

	CMP ES:[SI], VACIO
		JE fin_suma_dinamica

	ADD AX,ES:[SI]

	MOV SI, ES:[SI+4] 
	CMP SI,VACIO;AREA_DE_MEMORIA[pos] != VACIO
		JE salto_ejec_der_suma
	PUSH AX
	MOV AX,6
	MUL SI
	MOV SI,AX
	POP AX

	CALL calcular_suma_dinamico

	salto_ejec_der_suma:

	MOV SI, [BP+2] ;retoma contexto
	
	MOV SI, ES:[SI+2] 

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

	CMP SI,AREA_MEMORIA_BYTES	
		JG	fin_suma_estatica
	CMP ES:[SI], VACIO
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

