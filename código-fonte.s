; UTFPR - Universidade Tecnológica Federal do Paraná
; Projeto Final: Alarme - Microcontroladores 1
; Alunos: Francisco Miamoto e Vitor Moriya
; Prof. Paulo Henrique Eckwert Demantova

; Constante de tempo para o timer
TEMPO        EQU 55535
DELAY_BOUNCE EQU 30D
	
; Pinos para o Teclado
TECLADO EQU P0
COL3    EQU P0.0
COL2    EQU P0.1
COL1    EQU P0.2
COL0    EQU P0.3
LIN3    EQU P0.4
LIN2    EQU P0.5
LIN1    EQU P0.6
LIN0    EQU P0.7
; Pinos para o LCD	
LCD     EQU P2
D0      EQU P2.0
D1      EQU P2.1
D2      EQU P2.2
D3      EQU P2.3
D4      EQU P2.4
D5      EQU P2.5
D6      EQU P2.6
D7      EQU P2.7
EN      EQU P1.2
RW      EQU P1.1
RS      EQU P1.0
; Pinos para 7 segmentos
SEG7    EQU P3
SEG0    EQU P3.0
SEG1    EQU P3.1
SEG2    EQU P3.2
SEG3    EQU P3.3
; Pino para Buzzer
BUZZER  EQU P1.3
;Pinos para sensores
SENSOR1 EQU P1.4
SENSOR2 EQU P1.5
SENSOR3 EQU P1.6
SENSOR4 EQU P1.7

; Instruções para o LCD
FUNCTION_SET   EQU 0x3C ; 0x30 para 1 linha | 0x38 para 2 linhas
ENTRY_MODE	   EQU 0x06 ; 0x06 para incrementar endereço | 0x04 para decrementar endereço
LINHA_1        EQU 0x80
LINHA_2		     EQU 0xC0
CLEAR          EQU 0x01
RET_HOME       EQU 0x02
SCURSOR_LEFT   EQU 0x10
SCURSOR_RIGHT  EQU 0x14
SDISPLAY_LEFT  EQU 0x18
SDISPLAY_RIGHT EQU 0x1C
DISPLAY_MODE   EQU 0x0C ; 0x0F para Cursor e Blink ligados | 0x0C para ambos desligados | 0x0D para Cursor desligado e Blink ligado | 0x0E para Cursor ligado e Blink Desligado
DISPLAY_OFF	   EQU 0x03

; Endereços de memória para os bits utilizados:
SEN1       BIT  7FH
SEN2       BIT  7EH
SEN3       BIT  7DH
SEN4       BIT  7CH
FLAG       BIT  7BH
FLAG_2E    BIT  7AH

; Endereços dos dados na RAM:
SENHA0     DATA 30H
SENHA1     DATA 31H
SENHA2     DATA 32H
SENHA3     DATA 33H
SENHA4     DATA 34H
SENHA5     DATA 35H
CMP_SEN1   DATA 36H
CMP_SEN2   DATA 37H
CMP_SEN3   DATA 38H
CMP_SEN4   DATA 39H


;--------------------------------------------------------------
; Nome: Projeto Final - Alarme
; Função: Programa principal do projeto
;--------------------------------------------------------------
		       ORG 0000h
					 LJMP INICIO				
INICIO:	   LCALL LIMPA_VARIAVEIS
					 LCALL INICIA_LCD       ; Chama rotina de inicialização do LCD
					 SETB BUZZER            ; Desliga buzzer
					 LCALL SELF_TEST        ; Chama rotina de inicialização do alarme
					 LCALL CHECK_SENSORS    ; Chama rotina de confirmação dos sensores
					 MOV A,#CLEAR
					 LCALL INSTRUCAO_LCD    ; Limpa o display
DISPARADO: LCALL LE_SENHA         ; Chama rotina de leitura da senha
					 MOV A,#CLEAR            
					 LCALL INSTRUCAO_LCD    ; Limpa o display
					 LCALL VERIFICA_SENHA   ; Chama rotina de verificação da senha
					 LJMP ALARMA_DISPARA	  ; Chama rotina de decisão				 
					 
;--------------------------------------------------------------
; Nome: CHECK_LCD
; Função: Verifica disponibilidade do LCD
;--------------------------------------------------------------
CHECK_LCD:
					 CLR EN                  ; Clear EN
					 CLR RS			             ; Seta LCD para leitura (RW = 1 | RS = 0)	
					 SETB RW                 ;
					 MOV LCD, #0FFH          ; Valor para leitura de Busy Flag
					 SETB EN                 ; Seta EN
					 JB D7, CHECK_LCD        ; Enquanto D7 for valor lógico alto, pula para CHECK_LCD
					 CLR EN					         ; Clear EN
					 CLR RW                  ; Clear RW
					 RET                     ; Retorna 
;--------------------------------------------------------------
; Nome: TIMER 					                                      
; Funcão: Rotina de atraso de 10ms com multiplicador em R2    
;--------------------------------------------------------------
TIMER:		 		 
					 MOV TMOD,#01H           ; Timer no Modo 1
					 MOV TL0,#LOW(TEMPO)     ; Move parte baixa do byte TEMPO para TL0
					 MOV TH0,#HIGH(TEMPO)    ; Move parte alta do byte TEMPO para TL0
					 SETB TR0                ; Dispara o timer
OVERFLOW:	 JNB TF0, OVERFLOW       ; Enquanto TF0 não for setado pula para OVERFLOW
					 CLR TR0                 ; Limpa TR0
					 CLR TF0                 ; Limpa TF0
					 DJNZ R2,TIMER           ; Enquanto R2 não for 0, pula para TIMER
					
					 RET                     ; Retorna  
					 
;--------------------------------------------------------------
; Nome: ESCRITA_LCD				 
; Função: Envia um dado a ser escrito no LCD
;--------------------------------------------------------------
ESCRITA_LCD:
					 CLR A                   ; Limpa A
					 MOVC A,@A+DPTR          ; Move para A o caracter da posição em DPTR
					 JZ FIM_MSG              ; Caso o caracter seja zero, pula para FIM_MSG
					 CLR EN                  ; Limpa EN
					 CLR RW                  ; Seta LCD para escrita de dados (RW = 0 | RS = 1)
					 SETB RS                 ;
					 MOV LCD, A              ; Move para o barramento do LCD o valor em A
					 SETB EN                 ; Seta EN
					 LCALL CHECK_LCD         ; Verifica LCD
					 INC DPTR                ; Incrementa DPTR para obter próximo caracter 
					 JMP ESCRITA_LCD         ; Pula para ESCRITA_LCD 
FIM_MSG:	 
					 LCALL CHECK_LCD         ; Verifica LCD
					 RET                     ; Retorna

;--------------------------------------------------------------
; Nome: ESCRITA_CHAR_LCD
; Função: Envia um caracter a ser escrito no LCD
;--------------------------------------------------------------
ESCRITA_CHAR_LCD:
				   CLR EN				           ; Limpa EN
					 CLR RW                  ; Seta LCD para escrita de dados ((RW = 0 | RS = 1)
					 SETB RS                 ;
					 MOV LCD,A               ; Move para o barramento do LCD o valor em A
					 SETB EN                 ; Seta EN
					 LCALL CHECK_LCD         ; Verifica LCD
					 RET                     ; Retorna

;--------------------------------------------------------------
; Nome: INSTRUCAO_LCD
; Função: Envia uma instrução ao LCD
;--------------------------------------------------------------
INSTRUCAO_LCD:					 
					 LCALL CHECK_LCD         ; Verifica LCD 
					 CLR EN                  ; Limpa EN
					 CLR RW                  ; Seta LCD para escrita de instruções (RW = 0 | RS = 0)
					 CLR RS					 ;
					 MOV LCD, A              ; Move para o barramento do LCD o valor em A
					 SETB EN                 ; Seta EN
					 LCALL CHECK_LCD         ; Verifica LCD
					 RET                     ; Retorna

;--------------------------------------------------------------
; Nome: INICIA_LCD
; Função: Executa a rotina de inicialização do LCD
;--------------------------------------------------------------
INICIA_LCD:
; Verificando LCD
                     LCALL CHECK_LCD
; Function Set
					 CLR EN                  ; Clear EN
					 CLR RW                  ; Seta LCD para escrita de instruções (RW = 0 | RS = 0)
 					 CLR RS                  ;
					 MOV LCD, #FUNCTION_SET  ; Move para o barramento do LCD o valor da instrução Function Set
					 SETB EN			     ; Seta EN
					 LCALL CHECK_LCD	     ; Verifica LCD
; Display ON/OFF Control					 
					 CLR EN                  ; Clear EN
					 CLR RW                  ; Seta LCD para escrita de instruções (RW = 0 | RS = 0)
					 CLR RS					 ;
					 MOV LCD, #DISPLAY_MODE  ; Move para o barramento do LCD o valor da instrução Display Mode
					 SETB EN			     ; Seta EN
					 LCALL CHECK_LCD         ; Verifica LCD
; Display Clear
					 CLR EN                  ; Clear EN
					 CLR RW                  ; Seta LCD para escrita de instruções (RW = 0 | RS = 0)
					 CLR RS                  ;
					 MOV LCD, #CLEAR         ; Move para o barramento do LCD o valor da instrução Clear
					 SETB EN			     ; Seta EN
					 LCALL CHECK_LCD         ; Verifica LCD
; Entry Mode Set
					 CLR EN                  ; Clear EN
					 CLR RW                  ; Seta LCD para escrita de instruções (RW = 0 | RS = 0)
					 CLR RS                  ;
					 MOV LCD, #ENTRY_MODE    ; Move para o barramento do LCD o valor da instrução Entry Mode
					 SETB EN			     ; Seta EN
					 LCALL CHECK_LCD         ; Verifica LCD  
					 
					 RET                     ; Retorna
;--------------------------------------------------------------
; Nome: POSICAO_LCD
; Função: Seleciona a posicao a ser gravada no LCD (R0: Linha | R1: Coluna)
;--------------------------------------------------------------
POSICAO_LCD:
					PUSH ACC                 ; Salva A na pilha
				  CLR A                    ; Limpa A
					CJNE R0,#01H,SET_LINHA2  ; Compara o valor em R0 com 01h, se não for igual pula para SET_LINHA2
					DEC R1                   ; Caso seja R0 seja igual a 01h, decrementa R1 (Endereçamento a partir de 1)
					MOV A,#LINHA_1           ; Move o primeiro endereço da linha 1 para A
					ADD A,R1                 ; Soma A com R1, resultando na posição desejada
					LCALL INSTRUCAO_LCD      ; Envia como instrução A para o LCD, selecionando a posição
					LCALL CHECK_LCD          ; Verifica LCD
					JMP VOLTA                ; Pula para VOLTA
SET_LINHA2:
					DEC R1                   ; Decrementa R1
					ADD A,#LINHA_2           ; Move o primeiro endereço da linha 2 para A 
					ADD A,R1                 ; Soma A com R1, resultando na posição desejada
					LCALL INSTRUCAO_LCD      ; Envia como instrução A para o LCD
					LCALL CHECK_LCD          ; Verifica LCD
VOLTA: 	
					POP ACC                  ; Restaura A
					RET                      ; Retorna 

;--------------------------------------------------------------
; Nome: VARRE_TECLADO
; Função: Realiza a varredura e retorna a tecla pressionada
;--------------------------------------------------------------
VARRE_TECLADO:
					MOV P0,#0FFH
; Coluna 3
VARRE_COL3:
					SETB COL0
					CLR COL3
					JB LIN3, VARRE_COL3_LIN2
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL3_LIN3:
					JNB LIN3,ESPERA_COL3_LIN3
					MOV A,#"0"
					MOV B,#00H
					JMP RETORNO
VARRE_COL3_LIN2:
					JB LIN2, VARRE_COL3_LIN1
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL3_LIN2:
					JNB LIN2,ESPERA_COL3_LIN2
					MOV A,#"1"
					MOV B,#01H
					JMP RETORNO
VARRE_COL3_LIN1:
					JB LIN1, VARRE_COL3_LIN0
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL3_LIN1:
					JNB LIN1,ESPERA_COL3_LIN1
					MOV A,#"2"
					MOV B,#02H
					JMP RETORNO
VARRE_COL3_LIN0:
					JB LIN0, VARRE_COL2
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL3_LIN0:
					JNB LIN0,ESPERA_COL3_LIN0
					MOV A,#"3"
					MOV B,#03H
					JMP RETORNO
;Coluna 2
VARRE_COL2:
					SETB COL3
					CLR COL2
					JB LIN3, VARRE_COL2_LIN2
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL2_LIN3:
					JNB LIN3,ESPERA_COL2_LIN3
					MOV A,#"4"
					MOV B,#04H
					JMP RETORNO
VARRE_COL2_LIN2:
					JB LIN2, VARRE_COL2_LIN1
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL2_LIN2:
					JNB LIN2,ESPERA_COL2_LIN2
					MOV A,#"5"
					MOV B,#05H
					JMP RETORNO
VARRE_COL2_LIN1:
					JB LIN1, VARRE_COL2_LIN0
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL2_LIN1:
					JNB LIN1,ESPERA_COL2_LIN1
					MOV A,#"6"
					MOV B,#06H
					JMP RETORNO
VARRE_COL2_LIN0:
					JB LIN0, VARRE_COL1
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL2_LIN0:
					JNB LIN0,ESPERA_COL2_LIN0
					MOV A,#"7"
					MOV B,#07H
					JMP RETORNO
;Coluna 1
VARRE_COL1:
					SETB COL2
					CLR COL1
					JB LIN3, VARRE_COL1_LIN2
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL1_LIN3:
					JNB LIN3,ESPERA_COL1_LIN3
					MOV A,#"8"
					MOV B,#08H
					JMP RETORNO
VARRE_COL1_LIN2:
					JB LIN2, VARRE_COL1_LIN1
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL1_LIN2:
					JNB LIN2,ESPERA_COL1_LIN2
					MOV A,#"9"
					MOV B,#09H
					JMP RETORNO
VARRE_COL1_LIN1:
					JB LIN1, VARRE_COL1_LIN0
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL1_LIN1:
					JNB LIN1,ESPERA_COL1_LIN1
					MOV A,#"A"
					MOV B,#0AH
					JMP RETORNO
VARRE_COL1_LIN0:
					JB LIN0, VARRE_COL0
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL1_LIN0:
					JNB LIN0,ESPERA_COL1_LIN0
					MOV A,#"B"
					MOV B,#0BH
					JMP RETORNO
;Coluna 0
VARRE_COL0:
					SETB COL1
					CLR COL0
					JB LIN3, VARRE_COL0_LIN2
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL0_LIN3:
					JNB LIN3,ESPERA_COL0_LIN3
					MOV A,#"C"
					MOV B,#0CH
					JMP RETORNO
VARRE_COL0_LIN2:
					JB LIN2, VARRE_COL0_LIN1
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL0_LIN2:
					JNB LIN2,ESPERA_COL0_LIN2
					MOV A,#"D"
					MOV B,#0DH
					JMP RETORNO
VARRE_COL0_LIN1:
					JB LIN1, VARRE_COL0_LIN0
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL0_LIN1:
					JNB LIN1,ESPERA_COL0_LIN1
					MOV A,#"E"
					MOV B,#0EH
					JMP RETORNO
VARRE_COL0_LIN0:
					JNB LIN0, COLUNA_0
					JMP VARRE_COL3
COLUNA_0:					
					MOV R2,#DELAY_BOUNCE
					LCALL TIMER
ESPERA_COL0_LIN0:
					JNB LIN0,ESPERA_COL0_LIN0
					MOV A,#"F"
					MOV B,#0FH
RETORNO:
					RET

;--------------------------------------------------------------
; Nome: SELF_TEST
; Função: Rotina de inicialização do alarme
;--------------------------------------------------------------
SELF_TEST:
					 MOV R0,#1D
					 MOV R1,#4D
					 LCALL POSICAO_LCD      ; Seta cursor na posição Linha 1 Coluna 4
					 MOV DPTR,#MSG1         
					 LCALL ESCRITA_LCD      ; Escreve no display SELF TEST
					 MOV R0,#2
					 MOV R1,#1
					 LCALL POSICAO_LCD      ; Seta cursor para posição Linha 2 Coluna 1 
					 MOV R3,#16D            ; Move 16 para R3 para uso no DJNZ
					 MOV A,#"*"             ; Carrega acumulador com o caracter *
					 MOV SEG7,#00h          ; Move 0 para display de 7 segmentos
					 MOV R2,#75D
					 LCALL TIMER						; Espera 750ms
LOOP:			 LCALL ESCRITA_CHAR_LCD ; Escreve no display *	 
					 CLR BUZZER             ; Liga o buzzer
					 MOV R2,#25D            
					 LCALL TIMER            ; Espera 250ms
					 SETB BUZZER            ; Desliga buzzer
					 INC SEG7               ; Incrementa o display 7 segmentos
					 MOV R4,SEG7            ; Move os dados do 7 segmentos para R4 para comparação
					 CJNE R4,#0Ah,SEG_7     ; Compara R4 com 10, caso seja diferente pula para SEG_7
					 MOV SEG7,#00h          ; Caso R4 seja 10, zera SEG7
SEG_7:		 MOV R2,#75D            
					 LCALL TIMER            ; Espera 750ms
					 DJNZ R3,LOOP           ; Pula para LOOP
					 MOV SEG7,#0Fh          ; Move 0xF para display para apaga-lo
					 RET

;--------------------------------------------------------------
; Nome: CHECK_SENSORS
; Função: Rotina de confirmação dos sensores 
;--------------------------------------------------------------
CHECK_SENSORS:
					 MOV A,CLEAR
					 LCALL INSTRUCAO_LCD    ; Limpa o LCD
					 MOV R0,#1
					 MOV R1,#2
					 LCALL POSICAO_LCD      ; Seta a posição para Linha: 1 Coluna: 2
					 MOV DPTR,#MSG2         
					 LCALL ESCRITA_LCD      ; Mostra mensagem "Check sensors:"
					 MOV R0,#2
					 MOV R1,#1
					 LCALL POSICAO_LCD      ; Seta cursor para Linha: 2 Coluna: 1
					 MOV DPTR,#MSG3
					 LCALL ESCRITA_LCD      ; Escreve "1:"
					 LCALL LE_SENSORS       ; Lê sensores
					 MOV C,SEN1             ; Move o valor do sensor 1 para o carry
					 JC FECHADO0            ; Se C for 1, pula para FECHADO0
					 MOV A,#"A"             ; Caso C seja 0, coloca A no ACC para ser escrito
FEC0:      LCALL ESCRITA_CHAR_LCD ; Escreve o caracter em A
					 MOV DPTR,#MSG4
					 LCALL ESCRITA_LCD      ; Escreve a mensagem "2:"
					 MOV C,SEN2             ; Move o valor do sensor 2 para o carry
					 JC	 FECHADO1           ; Se C for 1, pula para FECHADO1
					 MOV A, #"A"            ; Caso C seja 0, coloca A no ACC para ser escrito
FEC1:			 LCALL ESCRITA_CHAR_LCD ; Escreve o caracter em A
					 MOV DPTR,#MSG5
					 LCALL ESCRITA_LCD      ; Escreve a mensagem "3:"
					 MOV C,SEN3             ; Move o valor do sensor 3 para o carry
					 JC FECHADO2            ; Se C for 1, pula para FECHADO2
					 MOV A, #"A"            ; Caso C seja 0, coloca A no ACC para ser escrito
FEC2:			 LCALL ESCRITA_CHAR_LCD ; Escreve o caracter em A
					 MOV DPTR,#MSG6
					 LCALL ESCRITA_LCD      ; Escreve a mensagem "4:"
					 MOV C,SEN4             ; Move o valor do sensor 4 para o carry
					 JC FECHADO3            ; Se C for 1, pula para FECHADO3
					 MOV A,#"A"             ; Caso C seja 0, coloca A no ACC para ser escrito
FEC3:			 LCALL ESCRITA_CHAR_LCD ; Escreve o caracter em A
CONFIRMA:	 LCALL VARRE_TECLADO    ; Varre o teclado
					 CJNE A,#"0",PROSEGUE   ; Se for pressionado 0, volta para o inicio
					 LJMP INICIO
PROSEGUE:	 CJNE A,#"1",CONFIRMA   ; Se for pressionado 1, o programa continua
					 RET
					 
FECHADO0:	 MOV A,#"F"           ; Coloca o caracter F no ACC para ser escrito
					 LJMP FEC0
					 
FECHADO1:  MOV A,#"F"           ; Coloca o caracter F no ACC para ser escrito
					 LJMP FEC1

FECHADO2:  MOV A,#"F"           ; Coloca o caracter F no ACC para ser escrito
					 LJMP FEC2
					  
FECHADO3:  MOV A,#"F"           ; Coloca o caracter F no ACC para ser escrito
					 LJMP FEC3
					 
;--------------------------------------------------------------
; Nome: LE_SENSORS
; Função: Rotina que lê os sensores e altera os bits correspondentes
;--------------------------------------------------------------
LE_SENSORS:
					 PUSH ACC             ; Salva ACC na pilha
					 CLR A                ; Limpa A
					 MOV C,SENSOR1        ; Move o valor do sensor 1 para C       
        	 JC  SETA_SENSOR1     ; Caso o valor em C seja 1, pula para SETA_SENSOR1
           CLR SEN1             ; Caso o valor em C seja 0, zera o bit SEN1 do segmento de memória
JMPSEN1:	 MOV C,SENSOR2        ; Move o valor do sensor 2 para C
					 JC  SETA_SENSOR2     ; Caso o valor em C seja 1 pula para SETA_SENSOR2
           CLR SEN2             ; Caso o valor em C seja 0, zera o bit SEN2 do segmento de memória
JMPSEN2:	 MOV C,SENSOR3        ; Move o valor do sensor 3 para C
					 JC  SETA_SENSOR3     ; Caso o valor em C seja 1 pula para SETA_SENSOR3
					 CLR SEN3             ; Caso o valor em C seja 0, zera o bit SEN3 do segmento de memória
JMPSEN3:   MOV C,SENSOR4        ; Move o valor do sensor 4 para C
         	 JC  SETA_SENSOR4	    ; Caso o valor em C seja 1 pula para SETA_SENSOR4
					 CLR SEN4             ; Caso o valor em C seja 0, zera o bit SEN4 do segmento de memória
JMPSEN4:   POP ACC              ; Restaura ACC
					 RET

SETA_SENSOR1: 
					 SETB SEN1            ; Seta o bit SEN1 do segmento de memória 
					 SJMP JMPSEN1
SETA_SENSOR2: 
					 SETB SEN2            ; Seta o bit SEN2 do segmento de memória
					 SJMP JMPSEN2
SETA_SENSOR3: 
					 SETB SEN3            ; Seta o bit SEN3 do segmento de memória
					 SJMP JMPSEN3
SETA_SENSOR4: 
					 SETB SEN4            ; Seta o bit SEN4 do segmento de memória
					 SJMP JMPSEN4

;--------------------------------------------------------------
; Nome: LE_SENHA
; Função: Rotina de leitura da senha e gravação na memória
;--------------------------------------------------------------
LE_SENHA:	 
           MOV R0,#1
					 MOV R1,#1
					 LCALL POSICAO_LCD      ; Seta cursor na posição Linha:1 Coluna:1
					 MOV DPTR,#MSG7       
					 LCALL ESCRITA_LCD      ; Escreve a mensagem "Digite a senha:"
					 MOV R0,#2
					 MOV R1,#5
					 LCALL POSICAO_LCD      ; Seta cursor na posição Linha:2 Coluna:5
					 LCALL VARRE_TECLADO    ; Varre o teclado
					 MOV SENHA0,A           ; Move para a memória o dado retornado do teclado
					 LCALL ESCRITA_CHAR_LCD ; Escreve no display a tecla pressionada
					 LCALL VARRE_TECLADO    ; Varre o teclado
					 MOV SENHA1,A           ; Move para a memória o dado retornado do teclado
					 LCALL ESCRITA_CHAR_LCD ; Escreve no display a tecla pressionada
					 LCALL VARRE_TECLADO    ; Varre o teclado
					 MOV SENHA2,A           ; Move para a memória o dado retornado do teclado
					 LCALL ESCRITA_CHAR_LCD ; Escreve no display a tecla pressionada
					 LCALL VARRE_TECLADO    ; Varre o teclado
					 MOV SENHA3,A           ; Move para a memória o dado retornado do teclado
					 LCALL ESCRITA_CHAR_LCD ; Escreve no display a tecla pressionada
					 LCALL VARRE_TECLADO    ; Varre o teclado
					 MOV SENHA4,A           ; Move para a memória o dado retornado do teclado  
					 LCALL ESCRITA_CHAR_LCD ; Escreve no display a tecla pressionada
					 LCALL VARRE_TECLADO    ; Varre o teclado
					 MOV SENHA5,A           ; Move para a memória o dado retornado do teclado 
					 LCALL ESCRITA_CHAR_LCD ; Escreve no display a tecla pressionada
					 RET
					 
;--------------------------------------------------------------
; Nome: VERIFICA_SENHA
; Função: Rotina de verificação da senha
;--------------------------------------------------------------
VERIFICA_SENHA:
ERROU:		 MOV DPTR,#MSG8        ; Carrega em DPTR o endereço da mensagem contendo a senha
					 CLR A                 ; Limpa A
					 MOVC A,@A+DPTR        ; Move para A o caracter da posição em DPTR
					 CJNE A,SENHA0,ERRADO  ; Caso o dado em A seja diferente do dado na memória pula para ERRADO
					 CLR A                 ; Se estiver igual, limpa A
					 INC DPTR              ; Incrementa DPTR
					 MOVC A,@A+DPTR        ; Move para A o próximo caracter
					 CJNE A,SENHA1,ERRADO  ; Caso o dado em A seja diferente do dado na memória pula para ERRADO
					 CLR A                 ; Se estiver igual, limpa A
					 INC DPTR              ; Incrementa DPTR
					 MOVC A,@A+DPTR        ; Move para A o próximo caracter
					 CJNE A,SENHA2,ERRADO  ; Caso o dado em A seja diferente do dado na memória pula para ERRADO
					 CLR A                 ; Se estiver igual, limpa A
					 INC DPTR              ; Incrementa DPTR
					 MOVC A,@A+DPTR        ; Move para A o próximo caracter
					 CJNE A,SENHA3,ERRADO  ; Caso o dado em A seja diferente do dado na memória pula para ERRADO
					 CLR A                 ; Se estiver igual, limpa A
					 INC DPTR              ; Incrementa DPTR
					 MOVC A,@A+DPTR        ; Move para A o próximo caracter
					 CJNE A,SENHA4,ERRADO  ; Caso o dado em A seja diferente do dado na memória pula para ERRADO
					 CLR A                 ; Se estiver igual, limpa A
					 INC DPTR              ; Incrementa DPTR
					 MOVC A,@A+DPTR        ; Move para A o próximo caracter
					 CJNE A,SENHA5,ERRADO  ; Caso o dado em A seja diferente do dado na memória pula para ERRADO
					 JMP CERTO					   ; Se a senha passar por todas as comparações pula para CERTO	 
ERRADO: 	 JB FLAG_2E,DBERROR    ; Caso o flag de 2 erros estiver setado, pula para DBERROR
					 JB FLAG,DBERROR       ; Caso o flag de 1 erro estiver setado, pula para DBERROR
					 SETB FLAG             ; Seta flag de 1 erro
					 MOV DPTR,#MSG10       
					 LCALL ESCRITA_LCD     ; Escreve a mensagem: "Senha incorreta"
				   CLR BUZZER            ; Liga o buzzer
					 MOV R2,#10          
					 LCALL TIMER           ; Espera 100ms
					 SETB BUZZER           ; Desliga buzzer
					 MOV R2,#20            
					 LCALL TIMER           ; Espera 200ms
					 CLR BUZZER            ; Liga buzzer
					 MOV R2,#10
					 LCALL TIMER           ; Espera 200ms 
					 SETB BUZZER           ; Desliga buzzzer
					 MOV R2,#160
					 LCALL TIMER           ; Espera 1600ms 
					 LCALL LE_SENHA        ; Chama rotina de leitura da senha
					 MOV A,#CLEAR           
					 LCALL INSTRUCAO_LCD   ; Limpa o display
					 SJMP ERROU		         ; Pula para label ERROU
DBERROR:   MOV A,#0H             ; Move 0x0 para A
					 SJMP VOLTA_V          
CERTO:	   MOV A,#1H             ; Move 0x1 para A
VOLTA_V:	 RET

;--------------------------------------------------------------
; Nome: ATIVA_ALARME
; Função: Rotina de verificação dos sensores e indicação no 7 segmentos
;--------------------------------------------------------------
ATIVA_ALARME:
				   CLR A                 ; Limpa A
					 MOV C,SEN1            ; Move para C o valor do sensor 1
					 MOV ACC.0,C           ; Move para o acumulador o carry
					 MOV CMP_SEN1,A        ; Move acumulador para byte de comparação 1 
					 CLR A                 ; Limpa A
					 MOV C,SEN2            ; Move para C o valor do sensor 2
					 MOV ACC.0,C           ; Move para o acumulador o carry
					 MOV CMP_SEN2,A        ; Move acumulador para byte de comparação 2
					 CLR A                 ; Limpa A
					 MOV C,SEN3            ; Move para C o valor do sensor 3
					 MOV ACC.0,C           ; Move para o acumulador o carry
					 MOV CMP_SEN3,A        ; Move acumulador para byte de comparação 3
					 CLR A                 ; Limpa A
					 MOV C,SEN4            ; Move para C o valor do sensor 4
					 MOV ACC.0,C           ; Move para o acumulador o carry
					 MOV CMP_SEN4,A        ; Move acumulador para byte de comparação 4
					 MOV A,#CLEAR          
					 LCALL INSTRUCAO_LCD   ; Limpa o LCD
					 MOV DPTR,#MSG11
					 LCALL ESCRITA_LCD     ; Escreve mensagem: "Alarme ON"
PISCA8:		 MOV SEG7,#08H         ; Move 0x8 para o 7 segmentos
					 MOV R2,#100
					 LCALL TIMER           ; Espera 1000ms
					 MOV SEG7,#0FH         ; Move 0xF para o 7 segmentos
					 MOV R2,#100         
					 LCALL TIMER           ; Espera 100ms
					 LCALL LE_SENSORS      ; Lê sensores
					 CLR A                 ; Limpa A
					 MOV C,SEN1            ; Move o valor atual do sensor 1 para o carry
					 MOV ACC.0,C           ; Move para o acumulador o carry
					 CJNE A,CMP_SEN1,MOSTRA_1 ; Compara A com o byte de comparação
					 CLR A                 ; Se for igual prossegue limpando A
					 MOV C,SEN2            ; Move o valor atual do sensor 2 para o carry
					 MOV ACC.0,C           ; Move para o acumulador o carry
					 CJNE A,CMP_SEN2,MOSTRA_2 ; Compara A com o byte de comparação
					 CLR A                 ; Se for igual prossegue limpando A
					 MOV C,SEN3            ; Move o valor atual do sensor 3 para o carry
					 MOV ACC.0,C           ; Move para o acumulador o carry
					 CJNE A,CMP_SEN3,MOSTRA_3 ; Compara A com o byte de comparação
					 CLR A                 ; Se for igual prossegue limpando A
					 MOV C,SEN4            ; Move o valor atual do sensor 4 para o carry
					 MOV ACC.0,C           ; Move para o acumulador o carry
					 CJNE A,CMP_SEN4,MOSTRA_4	 ; Compara A com o byte de comparação				 
					 LJMP PISCA8           ; Pula para pisca 8 caso não haja mudança nos sensores
MOSTRA_1:  MOV SEG7,#01H         ; Move para o display de 7 segmentos 0x1
					 SJMP ALARMA           ; Pula para ALARMA
MOSTRA_2:  MOV SEG7,#02H         ; Move para o display de 7 segmentos 0x2
					 SJMP ALARMA           ; Pula para ALARMA
MOSTRA_3:  MOV SEG7,#03H         ; Move para o display de 7 segmentos 0x3
					 SJMP ALARMA           ; Pula para ALARMA
MOSTRA_4:  MOV SEG7,#04H         ; Move para o display de 7 segmentos 0x1
					 SJMP ALARMA           ; Pula para ALARMA					 					 
ALARMA:    CLR BUZZER            ; Liga o buzzer
					 MOV A,#CLEAR          
					 LCALL INSTRUCAO_LCD   ; Limpa o LCD
					 MOV DPTR,#MSG13
					 LCALL ESCRITA_LCD     ; Escreve a mensagem "Sensor disparado"
					 MOV R2,#150D
					 LCALL TIMER	         ; Espera 1500ms 	 
					 SETB FLAG_2E          ; Seta flag de 2 erros
					 SETB FLAG             ; Seta flag de erro
					 LJMP DISPARADO        ; Pula para disparado
					 
;--------------------------------------------------------------
; Nome:  ALARMA_DISPARA
; Função: Rotina de decisão sobre a verificação da senha
;--------------------------------------------------------------
ALARMA_DISPARA:
					 CJNE A,#1H,DISPARA         ; Compara A com 0x1, se for diferente pula para DISPARA
					 JB FLAG_2E,DESATIVA_ALARME ; Se a senha estiver correta, caso a flag de 2 erros estaja setada, pula para DESATIVA ALARME
					 SETB BUZZER                ; Desliga buzzer
					 CLR FLAG_2E                ; Limpa flag de 2 erros
					 MOV DPTR,#MSG9             
					 LCALL ESCRITA_LCD          ; Escreve a mensagem: "Senha correta"
					 MOV R2,#150
					 LCALL TIMER                ; Espera 1500ms
					 LJMP ATIVA_ALARME         ; Chama rotina de ativar alarme
DISPARA:   SETB FLAG_2E               ; Seta flag de 2 erros
					 MOV DPTR,#MSG10      
					 LCALL ESCRITA_LCD          ; Escreve a mensagem: "Senha incorreta"
					 MOV R2,#150
					 LCALL TIMER                ; Espera 1500ms
					 CLR BUZZER                 ; Liga buzzer				
					 LJMP DISPARADO             ; Pula para label disparado9

					 
;--------------------------------------------------------------
; Nome:  DESATIVA_ALARME
; Função: Rotina para desativar o alarme
;--------------------------------------------------------------
DESATIVA_ALARME:
           SETB BUZZER                ; Desliga buzzer
					 MOV DPTR,#MSG12 
					 LCALL ESCRITA_LCD          ; Escreve a mensagem: "Alarme OFF"
					 MOV R2,#150
					 LCALL TIMER                ; Escreve a mensagem  "Alarme ON"
					 LJMP INICIO                ; Pula para o início
					 
;--------------------------------------------------------------
; Nome:  LIMPA_VARIAVEIS
; Função: Rotina para limpar variaveis
;--------------------------------------------------------------
LIMPA_VARIAVEIS:
					 SETB SENSOR1           ; Seta o bit SENSOR1 para atuar como entrada
					 SETB SENSOR2           ; Seta o bit SENSOR2 para atuar como entrada
					 SETB SENSOR3           ; Seta o bit SENSOR3 para atuar como entrada
					 SETB SENSOR4           ; Seta o bit SENSOR4 para atuar como entrada
					 CLR FLAG               ; Limpa flag de 1 erro
					 CLR FLAG_2E            ; Limpa flag de 2 erros
					 CLR SEN1               ; Limpa memória do sensor 1
					 CLR SEN2               ; Limpa memória do sensor 2
					 CLR SEN3               ; Limpa memória do sensor 3
					 CLR SEN4               ; Limpa memória do sensor 4
					 RET
					 
; Mensagens para o LCD
MSG1:         ;0123456789ABCDEF			 
		       DB "SELF TEST",00H
MSG2:			 
					 DB "Check sensors: ",00H
MSG3:      
           DB "1:",00H
MSG4:      
           DB " 2:",00H
MSG5:      
           DB " 3:",00H
MSG6:      
           DB " 4:",00H
MSG7:      
					 DB " Digite a senha:",00H	
MSG8:			
					 DB "123456"
MSG9:
					 DB " Senha correta",00H
MSG10:
					 DB "Senha incorreta",00H
MSG11:
					 DB "   Alarme ON",00H
MSG12:
					 DB "   Alarme OFF",00H
MSG13:
					 DB "Sensor disparado",00H

			 
				   END