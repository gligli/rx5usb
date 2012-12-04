#include <util/delay.h>

#include "flash.h"
#include "print.h"

#define CHIP_WAIT_US 1

static inline void flash_setData(unsigned char data)
{
	SET_DATA(data);
	_delay_us(CHIP_WAIT_US);
}

static inline unsigned char flash_getData(void)
{
	unsigned char b;
	
	SET_OE;
	_delay_us(CHIP_WAIT_US);
	b=GET_DATA;

	CLR_OE;
	
	return b;
}

static inline void flash_toggleWrite(void)
{
	SET_WE;
	DIR_DATA(0);

	_delay_us(CHIP_WAIT_US);
	CLR_WE;
	_delay_us(CHIP_WAIT_US);
	
	DIR_DATA(1);
}

void flash_setEnable(char enable)
{
	if(enable)
	{
		DIR_DATA(1);
		DIR_ADDR(0);
		DIR_WE(0);
		DIR_OE(0);
		
		CLR_WE;
		CLR_OE;
	}
	else
	{
		DIR_DATA(1);
		DIR_ADDR(1);
		DIR_WE(0);
		DIR_OE(1);
		
		CLR_WE;
		SET_OE;
	}
}

void flash_command(unsigned char cmd)
{
	SET_ADDR(0x555);
	flash_setData(0xaa);
	flash_toggleWrite();

	SET_ADDR(0x2aa);
	flash_setData(0x55);
	flash_toggleWrite();

	SET_ADDR(0x555);
	flash_setData(cmd);
	flash_toggleWrite();
}

void flash_printId(void)
{
	flash_command(0x90);
	
	SET_ADDR(0);
	
	print("mfg ");
	phex(flash_getData());
	print(" dev ");

	SET_ADDR(1);

	phex(flash_getData());
	print("\n");

	flash_command(0xf0);
}

void flash_chipErase(void)
{
	flash_command(0x80);
	flash_command(0x10);
	
	while(flash_getData()!=0xff);
}

void flash_programByte(unsigned long addr, unsigned char byte)
{
	flash_command(0xa0);
	
	SET_ADDR(addr);
	flash_setData(byte);

	SET_WE;
	DIR_DATA(0);

	_delay_us(CHIP_WAIT_US);
	
	while(flash_getData()!=byte);

	CLR_WE;

	_delay_us(CHIP_WAIT_US);
	
	DIR_DATA(1);
}

unsigned char flash_getByte(unsigned long addr)
{
	SET_ADDR(addr);
	return flash_getData();
}