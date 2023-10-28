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

