#ifndef FLASH_H
#define	FLASH_H

#define cbi(x,y) x&= ~_BV(y)
#define sbi(x,y)   x|= _BV(y)

#define SET_OE cbi(PORTB,PORTB4)
#define CLR_OE sbi(PORTB,PORTB4)
#define DIR_OE(x) {if(x) cbi(DDRB,PORTB4); else sbi(DDRB,PORTB4);}

#define SET_WE cbi(PORTB,PORTB5)
#define CLR_WE sbi(PORTB,PORTB5)
#define DIR_WE(x) {if(x) cbi(DDRB,PORTB5); else sbi(DDRB,PORTB5);}

#define SET_ADDR(x)												\
	PORTD=((uint32_t)x) & 0xff;					                \
	PORTC=(((uint32_t)x) >> 8) & 0xff;				            \
	PORTB=(PORTB & 0xf0) | ((((uint32_t)x) >> 16) & 0x0f);

#define DIR_ADDR(x)												\
{																\
	if(x)														\
	{															\
		DDRC=DDRD=0;											\
		DDRB&=0xf0;												\
	}															\
	else														\
	{															\
		DDRC=DDRD=0xff;											\
		DDRB|=0x0f;												\
	}															\
}

#define GET_DATA PINF
#define SET_DATA(x) PORTF=(x)
#define DIR_DATA(x) {if(x) DDRF=0; else DDRF=0xff;}

void flash_setEnable(char enable);
void flash_printId(void);
void flash_chipErase(void);
void flash_programByte(unsigned long addr, unsigned char byte);
unsigned char flash_getByte(unsigned long addr);

#endif	/* FLASH_H */

