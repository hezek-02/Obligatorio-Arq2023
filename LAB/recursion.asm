; Este programa muestra un algoritmo recursivo para buscar substrings en un string
; (examen diciembre 2016)
; La rutina en alto nivel:

; int existeSubstring(char* original, char* buscar)
; {
;   if (*original == NULL)
;     return 0;
;   else
;   {
;     char *iterOriginal = original; char *iterBuscar = buscar;
;     while (true)
;     {
;       if (*iterBuscar == NULL)
;         return 1;
;       else if (*iterBuscar == *iterOriginal)
;            {
;              iterBuscar++;
;              iterOriginal++;
;            }
;       else return existeSubstring(original+1, buscar);
;     }
;   }
; }

; Los strings se encuentran en ES. Los parámetros se pasan por stack y el resultado se devuelve en el stack

NULL equ 0
PUERTO_SALIDA equ 1
.data  ; Segmento de datos
#define DS 100h
#define SS 200h
cadena1 db "Este es un string donde voy a buscar substrings", 0
cadena2 db "Esta es otra cadena de caracteres", 0
buscar1 db "string", 0
buscar2 db "no va a estar", 0

.code  ; Segmento de código
  mov AX, DS
  mov ES, AX

  mov AX, offset cadena1
  push AX
  mov AX, offset buscar1
  push AX
  call existeSubstring
  pop AX
  out PUERTO_SALIDA, AL

  mov AX, offset cadena1
  push AX
  mov AX, offset buscar2
  push AX
  call existeSubstring
  pop AX
  out PUERTO_SALIDA, AL

  mov AX, offset cadena2
  push AX
  mov AX, offset buscar1
  push AX
  call existeSubstring
  pop AX
  out PUERTO_SALIDA, AL

  mov AX, offset cadena2
  push AX
  mov AX, offset buscar2
  push AX
  call existeSubstring
  pop AX
  out PUERTO_SALIDA, AL
  
  hlt ; para que pause la ejecucion aqui
loop: 
  jmp loop

existeSubstring proc
	mov bp, sp
	mov bx, [bp+4]
	cmp byte ptr ES:[bx], 0
	jne recorrer
	mov ax, 0
	jmp fin
recorrer:
	mov si, bx
	mov di, [bp+2]
while:
	cmp byte ptr es:[di], 0
	jne else_if
	mov ax, 1
	jmp fin
else_if:
	mov dl, es:[si]
	cmp es:[di], dl
	jne else
	inc si
	inc di
	jmp while
else:
	inc bx
	push bx
	push [bp+2]
	call existeSubstring
	pop ax
    mov bp,sp
fin:
	mov [bp+4], ax
	mov ax, [bp]
	mov [bp+2], ax
	add sp, 2
	ret
existeSubstring endp

.ports ; Definición de puertos
; 200: 1,2,3  ; Ejemplo puerto simple
; 201:(100h,10),(200h,3),(?,4)  ; Ejemplo puerto PDDV

.interrupts ; Manejadores de interrupciones
; Ejemplo interrupcion del timer
;!INT 8 1
;  iret
;!ENDINT
