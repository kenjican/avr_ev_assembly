;************************************************
;ASM learning, Kenji , 2017Aug06
;Electronic valve,UART,Stepper
;interrupt 如果没处理，mcu会死机
;************************************************

.include "./m2560def.inc"

.equ onesec = 15624
.equ GetStatusCmdSZ = 8
.equ rx_size = 255
.equ tx_size = 255
.equ eep_start = 0x0020

.dseg
.org 0x0200 ;重要！！2560的internal SRAM从0x0200开始，AVRASM2.exe编译的时候从0x0060开始，这样会存到ext I/O
txbuffer: .byte tx_size
rx_buffer: .byte rx_size
getst: .byte 8
txcnt: .byte 1

.cseg

.org 0x0000
rjmp reset

.org 0x0022
rjmp getv

.org 0x0036   ; UART0 tx int
reti;rjmp txgetv0
.org 0x0048  ;UART1 rx int
reti;rjmp rxgetv1
.org 0x004C  ;UART1 tx int
reti;rjmp txgetv


reset:
;////////
;set one second interrupt
;///////
  cli
  ldi r16,low(RAMEND)
  out spl,r16
  ldi r16,high(RAMEND)
  out sph,r16
  
  ldi r16,high(onesec);set the compare 15624 as one second
  sts ocr1ah,r16
  
  ldi r16,low(onesec)
  sts ocr1al,r16
  
  ldi r16,0b0000_0011
  sts timsk1,r16
  
  ldi r16,0b0000_1101
  sts tccr1b,r16 ;set prescaler as 1024,set CTC mode


;///////////
;set communication config
;//////////
  ldi r16,0x00
  ldi r17,0x19
  sts UBRR1H,r16
  sts UBRR1L,r17 ;set USART 1 baud rate 38400 ,P226
  
  sts UBRR0H,r16
  sts UBRR0L,r17 ;set USART 1 baud rate 38400 ,P226
  
  clr r16
  out EECR,r16
  ldi r16,3 << UCSZ00
  sts UCSR1C,r16 ;set USART1 8,None,1
  sts UCSR0C,r16 ;set USART0 8,None,1
  
  clr r16
  ldi r16,0b0101_1000
  sts UCSR1B,r16 ; enable tx,rx and interrupt.have to set the interrupt rjmp ,or mcu would hang
  sts UCSR0B,r16 ; enable tx,rx and interrupt.have to set the interrupt rjmp ,or mcu would hang
  
  ldi r16,0xff
  out DDRB,r16
  out PORTB,r16
/*
;///copy flash data to 
  ldi ZH,HIGH(hellow*2)
  ldi ZL,LOW( hellow*2)
  ldi XH,high(getst)
  ldi XL,low(getst)
  ;ldi r16,GetStatusCmdSZ
  rcall cpF2S
  ldi r16,0x07
  ldi XH,high(getst)
  ldi XL,low(getst)
*/
;///copy eeprom data to sram
  ldi r16,0x00
  out EECR,r16
  ldi r16,high(eep_start)  
  ldi r17,low(eep_start)
  out EEARH,r16
  out EEARL,r17
  ;rcall cpE2S
  rcall cpF2S
  ldi r16,0x07
  ldi XH,high(getst)
  ldi XL,low(getst)
  
  sei
;  ld r16,X+
;  sts UDR0,r16


  
loop:
rjmp loop
  
getv:
  ;ldi r20,0x08
  in r16,portb
  ldi r17,0xff
  eor r16,r17
  out portb,r16
  lpm r16,Z+
  ldi XH,high(getst)
  ldi XL,low(getst)
  ld r16,X+
  ;sts UDR1,r16
  ldi r16,EEDR
  sts UDR0,r16
  ldi r16,EEARL
  inc r16
  sts EEARL,r16
  reti

cpF2S:
  ;ldi r16,GetStatusCmdSZ
  lpm r17,Z+
  st X+,r17
  dec r16
  cpi r16,0
  brne cpF2S
  ret

cpE2S:
  sbic EECR,EEPE
  rjmp cpE2S
  sbi EECR,EERE
  in r17,EEDR
  st X+,r17
  in r17,EEARL
  inc r17
  sts EEARL,r17
  dec r16
  cpi r16,0
  brne cpE2S
  ret
  
txgetv0:
  dec r20
  cpi r20,0
  breq PC+3
  ld r16,X+
  ;ldi r16,EECR
  sts UDR0,r16
  ;sts UDR1,r16
  ;ldi r20,0x08
  reti
rxgetv1:
  ret