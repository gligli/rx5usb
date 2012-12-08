#include <util/delay.h>

#include "flash.h"
#include "print.h"

#define CHIP_WAIT_US 1

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

static void flash_command(unsigned char cmd)
{
	SET_ADDR(0x5555);
	SET_DATA(0xaa);
	flash_toggleWrite();

	SET_ADDR(0x2aaa);
	SET_DATA(0x55);
	flash_toggleWrite();

	SET_ADDR(0x5555);
	SET_DATA(cmd);
	flash_toggleWrite();
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

char flash_checkId(void)
{
	unsigned char mfg,dev;
	
	flash_command(0x90);
	
	SET_ADDR(0);
	
	mfg=flash_getData();
	print("mfg ");
	phex(mfg);
	print(" dev ");

	SET_ADDR(1);

	dev=flash_getData();
	phex(dev);
	print("\n");

	flash_command(0xf0);
	
	return (mfg==0xbf) && (dev==0xb5 || dev==0xb6 || dev==0xb7);
}

void flash_eraseChip(void)
{
	flash_command(0x80);
	flash_command(0x10);
	
	while(flash_getData()!=0xff);
//	_delay_ms(120);
}

void flash_eraseBlocks(unsigned long addr, unsigned long size)
{
	unsigned long i;
	
	for (i=0;i<size;i+=4096)
	{
		flash_command(0x80);
		
		SET_ADDR(0x5555);
		SET_DATA(0xaa);
		flash_toggleWrite();

		SET_ADDR(0x2aaa);
		SET_DATA(0x55);
		flash_toggleWrite();

		SET_ADDR(addr+i);
		SET_DATA(0x30);
		flash_toggleWrite();
	
		while((flash_getData()&0x80)!=0x80);
//		_delay_ms(30);
	}
}

void flash_programByte(unsigned long addr, unsigned char byte)
{
	flash_command(0xa0);
	
	SET_ADDR(addr);
	SET_DATA(byte);
	flash_toggleWrite();

	while(flash_getData()!=byte);
//	_delay_us(30);
}

unsigned char flash_getByte(unsigned long addr)
{
	SET_ADDR(addr);
	return flash_getData();
}