Racing	START	0
.........................................................
. 메인 루틴 구현 (MAIN)
MAIN	JSUB	STKINIT
	LDB	#INBUF
	BASE	INBUF
	JSUB	FIRST
	JSUB	SAVEDATA
	JSUB	FINDLOP
	+LDA	MIN
	COMP	=0xfffff
	JEQ	INVALID
	JSUB	ToASC
	J	kill

INVALID	CLEAR	X
	CLEAR	A
LoopINV	LDCH	invalid, X
	WD	OUTDEV
	TIX	#7
	JLT	LoopINV
	LDA	#0x0A
	WD	OUTDEV
	J	kill

kill	J	kill

invalid	BYTE	C'INVALID'
.........................................................

.........................................................
. 입력 서브루틴 구현 (INPUT)
.	get string and size from stdin
.	(return : (INBUF))
.	(used space : (X), (A), (INBUF), (T))
INPUT	STL	@TOP_A
	JSUB	PUSH_A

ckeckIN	TD	OUTDEV
	JEQ	ckeckIN
	TD	INDEV
	JEQ	ckeckIN
	JSUB	PRINPRM
	CLEAR	X
	CLEAR	A
	LDT	#1
LoopINP	RD	INDEV
	STCH	INBUF,X
	ADDR	T,X
	COMP	#0x0A	.0x0A = line feed('\n')
	JEQ	EOF_1
	J	LoopINP

EOF_1	JSUB	POP_A
	LDL	@TOP_A
	RSUB	

PRINPRM	CLEAR	X
LoopPRI	LDCH	PROMT,X
	WD	OUTDEV
	TIX	#3
	JLT	LoopPRI
	RSUB

INDEV	BYTE	0
OUTDEV	BYTE	1
PROMT	BYTE	C'>> '
INBUF	RESB	10
.........................................................

........................................................
. 	FIRST는 처음 입력 받은 값들을 N과 K에 저장하는 함수
FIRST	STL	@TOP_A
	JSUB	PUSH_A

	JSUB	INPUT
	LDA	#0
	STA	TEMP_3	. ToINT의 argument (TEMP_3)
	JSUB	ToINT
	LDA	TEMP_2
	STA	N	. N 값 결정
	JSUB	ToINT	. ToINT의 argument (TEMP_3)
	LDA	TEMP_2
	STA	K

	JSUB	POP_A
	LDL	@TOP_A
	RSUB

N 	RESW	1
K	RESW	1
........................................................


........................................................
. 입력값을 저장하는 서브루틴 구현 (SAVEDATA)
.
. 	SAVEDATA는 입력 받은 값들을 graph에 저장하는 함수
SAVEDATA
	STL	@TOP_A
	JSUB	PUSH_A

	LDX	#1	. 도시와 길이의 입력을 N-1으로 맞추기 위해
	STX	TEMP_4

LoopSAV	JSUB	INPUT
	LDA	#0
	STA	TEMP_3	. ToINT의 argument (TEMP_3) 세팅
	JSUB	ToINT
	LDA	TEMP_2
	STA	CITY_1	. city_1 set
	JSUB	ToINT	
	LDA	TEMP_2
	STA	CITY_2	. city_2 set
	JSUB	ToINT	
	LDA	TEMP_2
	STA	COST	. cost set
	JSUB	MKGRAPH

	LDX	TEMP_4
	TIX	N
	STX	TEMP_4
	JLT	LoopSAV

	JSUB	POP_A
	LDL	@TOP_A
	RSUB

.	그래프에 값들을 집어넣는 함수
MKGRAPH	LDA	CITY_1
	MUL	#3	
	MUL	N	. column 값 계산
	RMO	A, X
	LDA	CITY_2
	MUL	#3	. row 값 계산
	ADDR	A, X
	LDA	COST
	STA	GRAPH, X

	LDA	CITY_2
	MUL	#3	
	MUL	N	. column 값 계산
	RMO	A, X
	LDA	CITY_1
	MUL	#3	. row 값 계산
	ADDR	A, X
	LDA	COST
	STA	GRAPH, X

	RSUB

CITY_1	RESW	1
CITY_2	RESW	1
COST	RESW	1
GRAPH	RESW	20*20 . node수 N이 1~20까지 임으로 최대 크기는 20*20의 2D array
.........................................................

.........................................................
. <<< 경로의 길이가 K가 되는 최소 고속도로 개수를 찾는 함수들 >>>
FINDLOP	STL	@TOP_A
	JSUB	PUSH_A

	LDA	=0xfffff
	STA	MIN	. 처음 min을 -infinte 로 setting
	CLEAR	X
LoopFIN	STX	TEMP_1	. set argument of FINDMIN
	RMO	X, S
	JSUB	FINDMIN
	JSUB	FRESH
	RMO	S, X
	TIX	N
	JLT	LoopFIN

	JSUB	POP_A
	LDL	@TOP_A
	RSUB

.	argument : (TEMP_1) = i
.	return : (MIN)
.	used space : (TEMP_1), (TEMP_2), (T), (X)
FINDMIN	STL	@TOP_A
	JSUB	PUSH_A

	LDX	TEMP_1
	LDA	TRUE
	STCH	visited, X	. visited[X] = TRUE
	LDA	TEMP_1
	MUL	#3
	MUL	N	. set column = starting point
	STA	TEMP_1	. (TEMP_1) = column starting point
	CLEAR	X	. (X) = j set 0

LoopMIN	RMO	X, A
	MUL	#3	. set row
	ADD	TEMP_1
	ADD	#GRAPH
	STA	TEMP_2	. (TEMP_2) = GRAPH[TEMP_1][X]의 주소
	LDA	@TEMP_2	. GRAPH[TEMP_1][X] 값을 가지고 옴
	COMP	#0	. if GRAPH[TEMP_1][X] == 0
	JEQ	CDITION
	RMO	A, T	. (T) = GRAPH[TEMP_1][X]
	CLEAR	A
	LDCH	visited, X
	COMP	TRUE	. if visited[X] == TRUE
	JEQ	CDITION

	LDA	num
	ADD	#1	. num++
	STA	num
	LDA	sum
	ADDR	T, A	. (A) = sum + GRAPH[TEMP_1][X]

	COMP	K
	JLT	LOWER	. if sum < K
	JEQ	EQUAL	. if sum == K
	J	HIGHER	. if sum > K
	
LOWER	STA	sum
	STA	@TOP_B
	JSUB	PUSH_B	. push (sum)
	LDA	num
	STA	@TOP_B
	JSUB	PUSH_B	. push (num)
	STX	@TOP_B
	JSUB	PUSH_B	. push (X)
	STT	@TOP_B
	JSUB	PUSH_B	. push (T)
	LDA	TEMP_1
	STA	@TOP_B
	JSUB	PUSH_B	. push (TEMP_1)

	STX	TEMP_1	. argument setting for FINDMIN
	JSUB	FINDMIN	. recursive call

	JSUB	POP_B	. pop_A (TEMP_1)
	LDA	@TOP_B
	STA	TEMP_1
	JSUB	POP_B	. pop_A (T)
	LDT	@TOP_B
	JSUB	POP_B	. pop_A (X)
	LDX	@TOP_B
	LDA	FALSE
	STCH	visited, X
	JSUB	POP_B	. pop_A (num)
	LDA	@TOP_B
	SUB	#1
	STA	num	. num = current_num - 1
	JSUB	POP_B	. pop_A (sum)
	LDA	@TOP_B
	SUBR	T, A
	STA	sum	. sum = current_sum - GRAPH[TEMP_1][X]
	J	CDITION

EQUAL	LDA	num
	COMP	MIN	
	JLT	SETMIN	. if num=(A) > MIN
	J	FINSH
SETMIN	STA	MIN	. MIN <- num
	COMP	#1
	JEQ	STKFREE	. if MIN == 1, 더이상 찾을 필요가 없다. (알고리즘 성능을 높이기 위해)
	J	FINSH

HIGHER	LDA	num
	SUB	#1
	STA	num
	J	CDITION

CDITION	TIX	N
	JLT	LoopMIN
	J	FINSH

FINSH	JSUB	POP_A
	LDL	@TOP_A
	RSUB

.	num, sum, visited의 값을 0으로 set한다.
FRESH	CLEAR	A
	STA	sum
	STA	num
	CLEAR	X
LoopFR	STCH	visited, X
	TIX	N
	JLT	LoopFR
	RSUB

	LTORG
TRUE	WORD	1
FALSE	WORD	0
visited	RESB	20
MIN	RESW	1
sum	RESW	1
num	RESW	1
.........................................................

.........................................................
.	stack 관련 코드
STKINIT	LDA	#STACK_A
	STA	TOP_A
	LDA	#STACK_B
	STA	TOP_B
	RSUB

PUSH_A 	LDA	TOP_A
	ADD	#3
	STA	TOP_A
	RSUB

POP_A	LDA	TOP_A	
	SUB	#3
	STA	TOP_A
	RSUB

PUSH_B 	LDA	TOP_B
	ADD	#3
	STA	TOP_B
	RSUB

POP_B	LDA	TOP_B	
	SUB	#3
	STA	TOP_B
	RSUB

STKFREE	JSUB	STKINIT	. TOP을 초기화
	LDL	@TOP_A	. MAIN 루틴으로 이동하기 위해
	RSUB

TOP_A	RESW	1
TOP_B	RESW	1
STACK_A	RESW	50	. address 저장을 위한 stack
STACK_B	RESW	100	. data 저장을 위한 stack
.........................................................

.........................................................
.	convert input string to integer 
.	(argument : (INBUF), (TEMP_3) = 변환할 숫자의 시작 포인트) 
.	(return : (TEMP_2) = 변환된 integer 값, (TEMP_3) = 다음 변환할 숫자의 시작 포인트)
.	(used space : (TEMP_3), (TEMP_2), (TEMP_1), (A), (T), (X), (S) )
.	이 함수의 return 값은 무조건 양수값이다.
ToINT	STL	@TOP_A
	JSUB	PUSH_A

	LDX	TEMP_3	. (X) = 변환 시작 부분
	JSUB	CHKSIZE	. return값 (T)는 integer로 변환될 string의 크기를 가지고 있다.
	LDX	TEMP_3	. (X)값 복원
	CLEAR	A
	STA	TEMP_2	. clear TEMP_2
	ADDR	X, T
LoopINT	CLEAR	A
	LDCH	INBUF,X
	SUB	#0x30
	STA	TEMP_1	. (TEMP_1)은 자리수 더해주지 않은 integer를 가지고 있다.
	LDA	#1	. 자리수 계산시 mul을 위해
	RMO	X,S	. (S)는 자리수 계산에 쓰일 (X)를 위해 (X)값을 임시 보관한다.
MLOOP	TIXR	T	. 1의 자리인지 10자리인지 확인
	JEQ	SKIPMUL
	MUL	#10
	J	MLOOP
SKIPMUL	MUL	TEMP_1
	ADD	TEMP_2
	STA	TEMP_2
	RMO	S,X	. (X)값 복원
	TIXR	T
	JLT	LoopINT
	LDA	#1
	ADDR	T, A
	STA	TEMP_3

	JSUB	POP_A
	LDL	@TOP_A
	RSUB

.	(INBUF)에 있는 integer string의 크기를 채크한다.
.	(argument : (INBUF) , return : (T))
.	( (INBUF), (X), (A), (T), (S) )
CHKSIZE	CLEAR	A
	CLEAR	T
	LDS	#1
LoopCHK	LDCH	INBUF,X
	COMP	#0x20	.0x20 = blank space
	JEQ	EOF_2
	COMP	#0x0A	.0x0A = \n
	JEQ	EOF_2
	ADDR	S, T	. (T) = (T) + 1
	ADDR	S, X	. (X) = (X) + 1
	J	LoopCHK
EOF_2	RSUB
.........................................................


.........................................................
.	convert integer to ASCii and print it out
.	(argument : (MIN))
.	(used space : (TEMP_2), (A), (S), (T), (X))
ToASC	LDA	MIN		.MIN으로 들어올 수 있는 값은 1<= MIN <= 19
	LDT	#10		.MIN은 N-1 -> 최대값이 19임으로 2자리가 가장 큰 수이며 큰 수부터 출력하기 위해서 이와 같이 지정한다. 
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
	RSUB

CHECK0	STA	TEMP_2	.(X) flag가 1인지 0인지 확인
	RMO	X,A	
	COMP	#1	.(X) = 1인 경우
	LDA	TEMP_2
	JEQ	NOTSKIP
	J	SKIP	.(X) = 0인 경우
.........................................................


TEMP_1	RESW	1
TEMP_2	RESW	1
TEMP_3	RESW	1
TEMP_4	RESW	1
