#include <avr/io.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <string.h>
#include "usb_rawhid_debug.h"
#include "print.h"
#include "flash.h"

#define RX5USB_FW_VERSION 0x01
#define RX5USB_HID_TIMEOUT 100

#define CPU_PRESCALE(n)	(CLKPR = 0x80, CLKPR = (n))
#define CPU_16MHz       0x00
#define CPU_8MHz        0x01
#define CPU_4MHz        0x02
#define CPU_2MHz        0x03
#define CPU_1MHz        0x04
#define CPU_500kHz      0x05
#define CPU_250kHz      0x06
#define CPU_125kHz      0x07
#define CPU_62kHz       0x08

volatile uint8_t do_output=0;

uint8_t send_buffer[64];
uint8_t recv_buffer[64];

int main(void)
{
	unsigned long flash_addr,flash_size,flash_pos;
	int8_t r,i;

	flash_setEnable(0);
	
	// Initialize the USB, and then wait for the host to set configuration.
	// If the Teensy is powered without a PC connected to the USB port,
	// this will wait forever.
	usb_init();
	while (!usb_configured()) /* wait */ ;

	CPU_PRESCALE(CPU_16MHz);

	for(;;)
	{
		// Wait an extra second for the PC's operating system to load drivers
		// and do whatever it does to actually be ready for input
		_delay_ms(1000);

		print("RX5USB chip program mode\n");

		print("waiting header...\n");

		for(;;)
		{
			r = usb_rawhid_recv(recv_buffer,RX5USB_HID_TIMEOUT);

			if (r > 0 && recv_buffer[0]=='R'&& recv_buffer[1]=='X'&& recv_buffer[2]=='5' && recv_buffer[3]==RX5USB_FW_VERSION)
			{
				flash_addr=*(unsigned long*)&recv_buffer[4];
				flash_size=*(unsigned long*)&recv_buffer[8];
				break;
			}
		}

		print("a "); phex16(((uint32_t)flash_addr)>>16); phex16(flash_addr);
		print("\ns "); phex16(((uint32_t)flash_size)>>16); phex16(flash_size);
		print("\n");

		print("flash start...\n");

		flash_setEnable(1);

		print("id: ");
		if(!flash_checkId())
		{
			print("bad id!\n");
			for(;;);
		}

		print("erase...\n");
#if 1
		flash_eraseBlocks(flash_addr,flash_size);
#else
		flash_eraseChip();
#endif			

		print("ack header...\n");

		// resend the header, to ack it

		memcpy(send_buffer,recv_buffer,sizeof(recv_buffer));

		send_buffer[12]='O';
		send_buffer[13]='K';

		do
			r = usb_rawhid_send(send_buffer,RX5USB_HID_TIMEOUT);
		while (r<=0);

		print("chip program...\n");

		flash_pos=0;

		while(flash_pos<flash_size)
		{
			// get packet

			do
				r = usb_rawhid_recv(recv_buffer,RX5USB_HID_TIMEOUT);
			while (r!=sizeof(recv_buffer));

			// program it

			for(i=0;i<sizeof(recv_buffer);++i)
			{
				flash_programByte(flash_addr+flash_pos,recv_buffer[i]);
				++flash_pos;
			}

			// send what we red back from flash

			for(i=0;i<sizeof(send_buffer);++i)
			{
				send_buffer[i]=flash_getByte(flash_addr+flash_pos-sizeof(send_buffer)+i);
			}

			do
				r = usb_rawhid_send(send_buffer,RX5USB_HID_TIMEOUT);
			while (r!=sizeof(send_buffer));

			if((flash_pos&0x3fff)==0)
			{
				print(".");
			}
		}

		print("all done!\n");

		flash_setEnable(0);
	}
}
