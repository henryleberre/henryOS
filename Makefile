KERNEL_C_SRCS=$(wildcard ./*.c)
KERNEL_OBJS=$(KERNEL_C_SRCS:.c=.o)

all: dirs bootsector kernel

dirs:
    mkdir -p bin

%.o: %.c
    $(CC) -o $@ -c $<

%.bin: %.S:
    $(AS) -o $@ -c $<

bootsector: bootsector.bin

kernel: $(KERNEL_OBJS)

os: dirs bootsector kernel
    
    
