PROG=blinky
CC = arm-none-eabi-gcc
LD = arm-none-eabi-gcc
CP = arm-none-eabi-objcopy
CFLAGS = -c -mcpu=cortex-m4 -mthumb -Wall -O0
LFLAGS = -nostdlib -T stm32f401-rom.ld

OBJS = startup.o \
	main.o
all: $(PROG).elf $(PROG).bin
$(PROG).elf: $(OBJS)
	$(LD) $(LFLAGS) $^ -o $@
$(PROG).bin: $(PROG).elf
	$(CP) $(PROG).elf -O binary $(PROG).bin
%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@
	
clean: 
	rm -f $(OBJS) $(PROG).elf $(PROG).bin