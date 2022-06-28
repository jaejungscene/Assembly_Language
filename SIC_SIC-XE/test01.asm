MAIN	START	0x00000
	LDB	#TEMP04
	BASE	TEMP04
	LDA	=C'123456'	.'4'는 overflow로 A로 가지고 오지 못 한다.
	LDA	#A
	LDS	=C'123'
	LDA	BUFEND		.TEMP03의 address를 가리킴
	LDA	A
	LDA	#MAXLEN
	J	JUMP

	LTORG			.이 선언으로 lieral C'1234'의 위치가 이 위치로 바뀐다.
A	EQU	0x47/2		.SYMTAB에 생성될 뿐 object code에는 생성되지 않는다.
INDEV	BYTE	0
OUTDEV	BYTE	1
TEMP04	RESW	1
BUFFER	RESB	3
BUFEND	EQU	*		.SYMTAB에 생성될 뿐 object code에는 생성되지 않는다.
MAXLEN	EQU	BUFEND-BUFFER	.SYMTAB에 생성될 뿐 object code에는 생성되지 않는다.
TEMP03	WORD	0xf1		.밑 temp03과 같은 값이 저장되지만 저장공간만 다름
TEMP02	BYTE	X'F1'		.16진수 문자 그대로 저장이 됨 따라서 1btye 공간만 차지
TEMP01	BYTE	C'F1'		.F와 1에 대한 ascii코드 값을 저장함 따라서 2byte의 공간 차지
SPACE	RESW	0x1000


.앞에 BASE를 정의해 놓지 않으면 direct addressing을 한다.
.하지만 BASE를 정의해 놓으면 BASE를 통해 relative addressing을 한다.
.그리고 SPACE를 통해 주소간에 거리를 벌려놓지 않으면 그냥 (PC) relative addressing을 한다.
JUMP	LDX	#1
	STCH	TEMP01	
