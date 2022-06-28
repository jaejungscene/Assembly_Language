MAIN	START	1000

.	main flow
FIRST	TD	INDEV
	JEQ	FIRST
	JSUB	SETSIZE
	JSUB	STKINIT
LOOP	JSUB	PRIPROM
	JSUB	SCAN
	JSUB	TOPCOM
	JSUB	PUSHCOM
	JSUB	POPCOM
	JSUB	SUMCOM
	JSUB	PRICOM
	JSUB	PRIFAIL	.여기까지 온거면 command를 잘못 입력한 것임
	J	LOOP

STKINIT	LDA	#STACK
	STA	TOP
	RSUB

.	print ">> "
PRIPROM	CLEAR	X	
PRLOOP	LDCH	PROMPT,X
	WD	OUTDEV
	TIX	#3
	JLT	PRLOOP
	RSUB	

.	print "fail!"
PRIFAIL	CLEAR	X
	CLEAR	A
FALOOP	LDCH	FAILSTR,X
	WD	OUTDEV
	TIX	#5
	JLT	FALOOP
	LDA	#0x0A
	WD	OUTDEV
	RSUB

.	print "EMPTY" and go to LOOP
PRIEMTY	CLEAR	X
	CLEAR	A
EMLOOP	LDCH	EMTYSTR,X
	WD	OUTDEV
	TIX	#5
	JLT	EMLOOP
	LDA	#0x0A
	WD	OUTDEV
	J	LOOP

.	print "FULL" and go to LOOP
PRIFULL	CLEAR	X
	CLEAR	A
FULOOP	LDCH	FULLSTR,X
	WD	OUTDEV
	TIX	#4
	JLT	FULOOP
	LDA	#0x0A
	WD	OUTDEV
	J	LOOP


.	get string and size from stdin
.	(return : (INBUF), (INSIZE))
SCAN	CLEAR	X
	CLEAR	A
	LDT	#1
SCLOOP	RD	INDEV
	STCH	INBUF,X
	ADDR	T,X
	COMP	#0x0A	.0x0A = line feed('\n')
	JEQ	EOF01
	J	SCLOOP
EOF01	RMO	X,A
	SUB	#1
	STA	INSIZE
	RSUB	


.	convert input string to integer 
.	(argument : (INBUF) , return : (TEMP_2))
.	(written space : (TEMP_2), (TEMP_1), (A), (T), (X))
.	integer range :	-8388608 ~ 8388607 (-2^23 ~ 2^23-1)
CVRINT	CLEAR	X
	CLEAR	T
	STX	TEMP_2
CVLOOP	CLEAR	A
	LDCH	INBUF,X
	COMP	#0x2D	.0x2D = '-'
	JEQ	MINUSFL	.if input number is minus, go to MINUSFL
	SUB	#0x30
	STA	TEMP_1
	LDA	#1
	RMO	X,S	
MLOOP	TIX	INSIZE
	JEQ	SKIPMUL
	MUL	#10
	J	MLOOP
SKIPMUL	MUL	TEMP_1
	ADD	TEMP_2
	STA	TEMP_2
	RMO	S,X
	TIX	INSIZE
	JLT	CVLOOP
	RMO	T,A
	COMP	#1	.if (T)==1, so input number is minus
	JEQ	MINUS	.go to MINUS
	RSUB

MINUSFL	LDT	#1	.(T)는 flag로 사용됨, 즉 T==1이면, 음수
	ADDR	T,X
	J	CVLOOP

MINUS	LDA	#0	.양수형태로 계산된 결과를 2보수를 취해 음수 형태로 바꾸어줌
	SUB	TEMP_2
	STA	TEMP_2
	RSUB


.	convert integer to ASCii and print it out
.	(argument : (A))
.	(written space : (TEMP_2), (A), (S), (T), (X))
CVRASC	LDT	=1000000	.숫자의 범위가 -8388608 ~ 8388607 임으로 7자리가 가장 큰 수이며 큰 수부터 출력해야하기 때문에 
	RMO	A,S		.(S) <- CVRLOOP를 돌때 div 값이 나오면 맨 앞값은 없앤 후 남은 값이다
	COMP	#0
	JEQ	IFZERO
	AND	=0x800000
	COMP	=0x800000	.most significant bit가 1인지를 확인해 음수인지 양수인지 판단한다인
	JEQ	MINUSCV	
	CLEAR	X		.flag로 사용 : (X)가 1일 때 부터는 0도 출력 값으로 내보내야 함.
CVRLOOP	RMO	S,A
	DIVR	T,A		.(T) <- 숫자의 맨 앞 값을 추출해내기 위해 쓰임
	COMP	#0
	JEQ	CHECKFL
	LDX	#1
NOTSKIP	ADD	#0x30
	WD	OUTDEV
	SUB	#0x30
	MULR	T,A
	SUBR	A,S		.(S)의 값을 terminal로 나간 정수의 값만큼 빼줌
SKIP	RMO	T,A	
	DIV	#10
	COMP	#0
	JEQ	FINCVR
	RMO	A,T
	J	CVRLOOP
FINCVR	RSUB

IFZERO	ADD	#0x30	.output값이 0인 경우
	WD	OUTDEV
	RSUB

CHECKFL	STA	TEMP_2	.(X) flag가 1인지 0인지 확인
	RMO	X,A	
	COMP	#1	.(X) = 1인 경우
	LDA	TEMP_2
	JEQ	NOTSKIP
	J	SKIP	.(X) = 0인 경우

MINUSCV	LDA	#0x2D	.음수면 '-'먼저 terminal인 내보냄
	WD	OUTDEV
	LDA	#0
	SUBR	S,A
	RMO	A,S
	CLEAR	X
	J	CVRLOOP


.	set size of stack
.	(return : (STKSIZE))
SETSIZE	STL	RETADDR
SETAGIN	JSUB	PRIPROM
	JSUB	SCAN	.(X)-1 = size of input
	LDA	INSIZE
	COMP	#0
	JEQ	FAIL01
	JSUB	CVRINT	
	LDA	TEMP_2
	COMP	#1
	JLT	FAIL01
	COMP	#99	
	JGT	FAIL01
	STA	STKSIZE
	LDL	RETADDR
	RSUB
FAIL01	JSUB	PRIFAIL
	J	SETAGIN


.	operation for TOP command
TOPCOM	CLEAR	X
	CLEAR	A
TOPLOOP	LDCH	INBUF,X
	RMO	A,T
	LDCH	TOPSTR,X
	COMPR	A,T
	JLT	FAIL02
	JGT	FAIL02
	TIX	#3
	JLT	TOPLOOP
	LDCH	INBUF,X
	COMP	#0x0A	
	JEQ	TOPFUNC
FAIL02	RSUB

TOPFUNC	LDA	TOP
	COMP	#STACK
	JEQ	PRIEMTY
	SUB	#3
	STA	TEMP_1
	LDA	@TEMP_1	
	JSUB	CVRASC
	LDA	#0x0A
	WD	OUTDEV
	J	LOOP


.	operation for PUSH command
PUSHCOM	CLEAR	X
	CLEAR	A
PUSLOOP	LDCH	INBUF,X
	RMO	A,T
	LDCH	PUSHSTR,X
	COMPR	A,T
	JLT	FAIL03
	JGT	FAIL03
	TIX	#4
	JLT	PUSLOOP
	LDCH	INBUF,X
	COMP	#0x0A
	JEQ	PUSFUNC
FAIL03	RSUB

PUSFUNC	LDA	STKSIZE
	MUL	#3
	LDT	#STACK
	ADDR	T,A
	COMP	TOP
	JEQ	PRIFULL
	JSUB	SCAN
	JSUB	CVRINT
	LDA	TEMP_2
	STA	@TOP
	JSUB	PUSH
	J	LOOP

PUSH	LDA	TOP
	ADD	#3
	STA	TOP
	RSUB


.	operation for POP command
POPCOM	CLEAR	X
	CLEAR	A
POPLOOP	LDCH	INBUF,X
	RMO	A,T
	LDCH	POPSTR,X
	COMPR	A,T
	JLT	FAIL04
	JGT	FAIL04
	TIX	#3
	JLT	POPLOOP
	LDCH	INBUF,X
	COMP	#0x0A
	JEQ	POPFUNC
FAIL04	RSUB

POPFUNC	LDA	TOP
	COMP	#STACK
	JEQ	PRIEMTY
	JSUB	POP
	CLEAR	A
	STA	@TOP
	J	LOOP

POP	LDA	TOP
	SUB	#3
	STA	TOP
	RSUB


.	operation of SUM command
SUMCOM	CLEAR	X
	CLEAR	A
SLOOP	LDCH	INBUF,X
	RMO	A,T
	LDCH	SUMSTR,X
	COMPR	A,T
	JLT	FAIL05
	JGT	FAIL05
	TIX	#3
	JLT	SLOOP
	LDCH	INBUF,X
	COMP	#0x0A
	JEQ	SUMFUNC
FAIL05	RSUB

SUMFUNC	CLEAR	T
	LDA	TOP
	COMP	#STACK
	JEQ	PRIEMTY
SUMLOOP	SUB	#3
	COMP	#STACK
	JLT	FINSUM
	STA	TEMP_1
	LDA	@TEMP_1
	ADDR	A,T
	LDA	TEMP_1
	J	SUMLOOP
FINSUM	RMO	T,A
	JSUB	CVRASC
	LDA	#0x0A
	WD	OUTDEV
	J	LOOP


.	operation of PRINT command
PRICOM	CLEAR	X
	CLEAR	A
PLOOP	LDCH	INBUF,X
	RMO	A,T
	LDCH	PRISTR,X
	COMPR	A,T
	JLT	FAIL06
	JGT	FAIL06
	TIX	#5
	JLT	PLOOP
	LDCH	INBUF,X
	COMP	#0x0A
	JEQ	PRIFUNC
FAIL06	RSUB

PRIFUNC	LDA	#STACK
	COMP	TOP
	JEQ	PRIEMTY
PRILOOP	STA	TEMP_1
	LDA	@TEMP_1
	JSUB	CVRASC
	LDA	#0x20	.0x20 = blank
	WD	OUTDEV
	LDA	TEMP_1
	ADD	#3
	COMP	TOP
	JLT	PRILOOP
	LDA	#0x0A
	WD	OUTDEV
	J	LOOP


INDEV	BYTE	0
OUTDEV	BYTE	1
PROMPT	BYTE	C'>> '
FAILSTR	BYTE	C'fail!'
EMTYSTR	BYTE	C'EMPTY'
FULLSTR	BYTE	C'FULL'
TOPSTR	BYTE	C'TOP'
PUSHSTR	BYTE	C'PUSH'
POPSTR	BYTE	C'POP'
SUMSTR	BYTE	C'SUM'
PRISTR	BYTE	C'PRINT'
RETADDR	RESW	1	.extra return address
TEMP_1	RESW	1	
TEMP_2	RESW	1
INSIZE	RESW	1	.store input size
INBUF	RESB	10	.store input string
STKSIZE	RESW	1	.store stack size
TOP	RESW	1	
STACK	RESW	99