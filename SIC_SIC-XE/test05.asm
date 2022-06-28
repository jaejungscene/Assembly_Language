test5    START 0
	EXTREF push
	EXTREF	TMP
	EXTDEF result
	
	JEQ 	exit     . if A == 1 then exit
	+LDA	TMP
	+JSUB 	push   . push A
exit    RSUB
	
result  WORD 1