.data
#define DS 100h
ORG 10

texto db "ArquiSim", 0
largo db 8

numFact dw 9

lista dw 11, 2, 7, 4, 5, 10, 1, 8, 9, 6, 3, 0
suma dw 66

dos dw 2

.code
  cli
  mov bx, offset texto
  call len
  xor ax, ax
  mov al, byte ptr [largo]
  cmp di, ax				; Comparo el largo del texto con el resultado de la llamada al procedimiento len
  jne finError

  mov ax, [numFact]
  call factIter				; Calculo el factorial de 'var' de forma iterativa
  mov bx, dx				; Guardo la parte alta del resultado en BX
  mov cx, ax				; Guardo la parte baja del resultado en CX
  xor ax, ax
  mov ax, [numFact]
  call factRec				; Calculo el factorial de 'var' de forma recursiva
  cmp dx, bx				; Comparo la parte alta de ambos resultados
  jne finError
  cmp ax, cx				; Comparo la parte baja de ambos resultados
  jne finError
  
  mov bx, offset lista
  call suma_lista
  cmp ax, [suma]				; Comparo la salida con lo que deberia dar la suma
  jne finError

  mov ax, 60
  mov bx, 48
  call mcd
  cmp cx, 12				; MCD 60,48 = 12
  jne finError

; Prueba ADC
  stc
  mov bx, 0xFFFD
  mov ax, 1
  adc ax, bx
  pushf
  cmp ax, 0xFFFF
  jne finError
  popf
  jns finError
  jc finError

; Prueba SUB y SBB
  mov ax, 1
  mov bx, [dos]
  sub ax, bx
  sbb ax, 0
  pushf
  cmp ax, -2				; 1 - 2 - 1 = -2
  jne finError
  popf
  jc finError
  jns finError

; Prueba CBW
  mov al, -1
  cbw
  cmp ax, 0xFFFF
  jne finError
  mov al, 5
  cbw
  cmp ax, 5
  jne finError

; Prueba DEC
  dec word ptr [dos]
  cmp word ptr [dos], 1
  jne finError
  dec word ptr [dos]
  dec word ptr [dos]
  cmp word ptr [dos], -1
  jne finError
  add word ptr [dos], 2
  inc word ptr [dos]
  cmp word ptr [dos], 2
  jne finError

; Prueba AND
  mov ax, 1b
  and ax, 0
  cmp ax, 0
  jne finError
  inc ax
  add ax, 1
  and ax, -1
  cmp ax, 2
  jne finError

  mov byte ptr [dos+2], 5
  mov ax, [dos+2]
  mov byte ptr [dos+3], 3
  and [dos+3], ax
  cmp byte ptr [dos+3], 1
  jne finError

; Prueba OR
  mov ax, 5
  mov [dos+2], 0xFFFE
  or ax, [dos+2]
  cmp ax, -1
  jne finError

; Prueba XOR
  mov byte ptr [dos+4], 1010b
  mov al, 0101b
  xor [dos+4], al
  cmp byte ptr [dos+4], 15
  jne finError

; Prueba NOT
  mov ax, 0
  not al
  cmp al, -1
  jne finError
  mov ax, 0
  not ax
  cmp ax, -1
  jne finError

; Prueba SAL
  mov byte ptr [dos+2], 1
  sal byte ptr [dos+2], 1
  cmp byte ptr [dos+2], 2
  jne finError
  sal byte ptr [dos+2], 1
  cmp byte ptr [dos+2], 4
  jne finError
  mov cl, 2
  sal byte ptr [dos+2], cl
  cmp byte ptr [dos+2], 16
  jne finError

; Prueba SAR
  mov ax, -1
  sar ax, 1
  cmp ax, -1
  jne finError
  mov cl, 12
  sar ax, cl
  cmp ax, 0xFFFF
  jne finError
  mov ax, 0x4000
  mov cl, 14
  sar ax, cl
  cmp ax, 1
  jne finError

; Prueba SHR
  mov ax, -1
  shr ax, 1
  cmp ax, 0x7FFF
  jne finError
  mov cl, 14
  shr ax, cl
  cmp ax, 1
  jne finError

; Prueba ROL
  mov ax, -1
  rol ax, 1
  pushf
  cmp ax, -1
  jne finError
  popf
  jo finError
  mov ax, 0x8000
  rol ax, 1
  pushf
  cmp ax, 1
  jne finError
  popf
  jno finError
  mov cl, 15
  rol ax, cl
  cmp ax, 0x8000
  jne finError

; Prueba ROR
  mov ax, -1
  ror ax, 1
  pushf
  cmp ax, -1
  jne finError
  popf
  jo finError
  mov cl, 16
  ror ax, cl
  cmp ax, -1
  jne finError
  mov ax, 1
  ror ax, cl
  cmp ax, 1
  jne finError
  ror ax, 1
  pushf
  cmp ax, 0x8000
  jne finError
  popf
  jno finError

; Prueba de la interrupcion del clock
  mov AX,0xABCD
  mov BX,0
  sti

fin:
  jmp fin

finError:
  hlt
  jmp finError				; Si la ejecucion termina aca hubo un error de calculo

; Procedimiento que calcula el largo de un string.
; El desplazamiento del string respecto a DS se recibe en BX.
; El resultado se devuelve en DI.
len proc
 xor di,di
while_len:
 cmp byte ptr [bx+di], 0
 je fin_len
 inc di
 jmp while_len
fin_len:
 ret
len endp

; Procedimiento RECURSIVO para calcular el factorial de un numero entre 0 y 9 recibido en AX.
; El resultado se devuelve en DX::AX.
factRec proc
	cmp ax, 0
	jbe paso_base_factRec
	push bx
	push ax
	dec ax
	call factRec
	pop bx
	mul bx
	pop bx
	jmp fin_factRec
	
	paso_base_factRec:
	mov ax, 1

	fin_factRec:
	ret
factRec endp

; Procedimiento ITERATIVO para calcular el factorial de un numero entre 0 y 9 recibido en AX.
; El resultado se devuelve en DX::AX.
factIter proc
  push bx
  push cx
  mov bx, ax
  mov ax, 1
  mov cx, 1
while_factIter:
  mul cx
  inc cx
  cmp cx, bx
  jbe while_factIter
  pop cx
  pop bx
  ret
factIter endp

; Procedimiento que suma una lista de numeros hasta que encuentra el valor 0.
; El desplazamiento de la lista respecto de DS se recibe en BX.
; El resultado se devuelve en AX.
suma_lista proc
  push cx					; guardo registro auxiliar
  cmp word ptr [bx], 0	; si el valor no es 0
  je paso_base_suma_lista ; salto al paso base
	
; si no es NULL
  mov cx, [bx]			; guardo el valor del item actual
  add bx, 2				; actualizo el puntero al siguiente
  call suma_lista			; llamada recursiva
  add ax, cx				; sumo valor actual + retornado por suma_lista
  jmp fin_suma_lista		; salto al final

paso_base_suma_lista:
  mov ax, 0				; paso base es retornar cero

fin_suma_lista:
  pop cx					; dejo el stack como estaba originalmente
  ret
suma_lista endp

; Procedimiento para calcular el Maximo Comun Divisor entre dos numeros.
; Los numeros se reciben en AL y BL.
; El resultado se devuelve en CX.
mcd proc
  push ax
  push bx
  push dx
  xor cx, cx
  xor dx, dx
  mov ah, 0
  cmp al, bl
  ja next
  mov dl, bl
  mov bl, al
  mov al, dl
next:
  mov cl, bl
  div bl
  cmp ah, 0
  je fin_mcd
  mov al, bl
  mov bl, ah
  mov ah, 0
  jmp next
fin_mcd:
  pop dx
  pop bx
  pop ax
  ret
mcd endp

.ports
200: 1h

.interrupts
!INT 8 1
  mov [BX+0],AX
  add BX,2
  iret
!ENDINT

!INT 9 1
  mov AX, 0x1234
  iret
!ENDINT
