MAIN	START	1000
FIRST	JSUB	STKINIT

	LDA	#0	
        STA	@TOP
        LDA	TOP
	ADD	#3
	STA	TOP

	LDA	#1	.1번째 fibonacci값 1을 바로 출력시키기 위해 저장
	JSUB	STORE	
	
FBNCC   LDA     INDEX
        ADD     #1
        STA     INDEX
        COMP    #7	.fibonacci수열 1~7번째까지만 출력
        JEQ     A
        
        LDA	TOP	
	SUB	#3
	STA	TOP
	LDA	@TOP
	STA	DATA1	.n번째 fibonacci수열 값을 계산하기 위해 n-1번째 값을 DATA1에 저장
	
	LDA	TOP
	SUB	#3
	STA	TOP
	LDA	@TOP
	STA	DATA2	.n-2번째 값을 DATA2에 저장
	
	LDA	TOP
	ADD	#6
	STA	TOP	.수열 계산을 위해 옮겨진 TOP 위치 원상복귀
	
	LDA	DATA1	
	ADD	DATA2
	JSUB	STORE
	J       FBNCC
	
A	J	A

STORE	STA	@TOP	.n번째 계산된 fibonacci 수열 값을 출력하기 위해 TOP에 임시 저장
	J       PRINT

CNTINU  LDA	TOP	.top위치 한 증가
	ADD	#3
	STA	TOP
	RSUB		.A	J	A의 바로 위 instruction으로 감

PRINT	COMP    #10	.한자리 수인지 두자리 수인지 판별
        JLT     PRINT9
        COMP    #100
        JLT     PRINT99

PRINT9  TD	OUTDEV	.한자리 수 출력
	JEQ	PRINT9
	ADD     #48
	WD	OUTDEV
        LDA     #10
	WD	OUTDEV
        J       CNTINU
        
PRINT99 TD	OUTDEV	.두자리 수 출력
	JEQ	PRINT9
        STA     DATA3
        DIV     #10
        ADD     #48
        WD	OUTDEV
        SUB     #48
        
        MUL     #10
        STA     DATA4
        LDA     DATA3
        SUB     DATA4
        ADD     #48
        WD	OUTDEV
        LDA     #10
	WD	OUTDEV
        J       CNTINU

STKINIT LDA	#FIBO
	STA	TOP
	RSUB
	

OUTDEV	BYTE	1
FIBO	RESW	10
TOP	RESW	1
DATA1	RESW	1
DATA2	RESW	1
DATA3	RESW	1
DATA4	RESW	1
INDEX	RESW	1
