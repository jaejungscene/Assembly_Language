.........................................................
.	convert integer to ASCii and print it out
.	(argument : (MIN))
.	(used space : (TEMP_2), (A), (S), (T), (X))
ToASC	LDA	MIN		.MIN으로 들어올 수 있는 값은 1<= MIN <= 19
	LDT	#10		.MIN은 N-1 -> 최대값이 19임으로 2자리가 가장 큰 수이며 큰 수부터 출력해야 위해서 이와 같이 지정한다. 
	RMO	A,S		.(S) <- LoopASC를 돌때 div 값이 나오면 맨 앞값은 없앤 후 남은 값이다
	CLEAR	X		.flag로 사용 : (X)가 1일 때 부터는 0도 출력 값으로 내보내야 함.
LoopASC	RMO	S,A
	DIVR	T,A		.숫자의 맨 앞 값을 추출해냄
	COMP	#0		
	JEQ	CHECK0		.if( (MIN)/(T) == 0 )
	LDX	#1		. flag (X) <- 1
NOTSKIP	ADD	#0x30
	WD	OUTDEV
	SUB	#0x30
	MULR	T,A
	SUBR	A,S		.(S)의 값을 terminal로 나간 정수의 값만큼 빼줌
SKIP	RMO	T,A	
	DIV	#10
	COMP	#0
	JEQ	EOF_3
	RMO	A,T
	J	LoopASC

EOF_3	LDA	#0x0A
	WD	OUTDEV
	J	kill

CHECK0	STA	TEMP_2	.(X) flag가 1인지 0인지 확인
	RMO	X,A	
	COMP	#1	.(X) = 1인 경우
	LDA	TEMP_2
	JEQ	NOTSKIP
	J	SKIP	.(X) = 0인 경우

kill	J	kill
.........................................................

OUTDEV	BYTE	1

MIN	WORD	99
TEMP_1	RESW	1
TEMP_2	RESW	1
TEMP_3	RESW	1

INVALID	BYTE	C'INVALID'