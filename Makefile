KERNEL_C_SRCS   = $(wildcard kernel/*.c)
KERNEL_C_OBJS   = $(KERNEL_C_SRCS:.c=.o)

KERNEL_C_FLAGS  = -m32 -Wno-pointer-arith -Wno-unused-parameter
KERNEL_C_FLAGS += -nostdlib -nostdinc -ffreestanding -fno-pie
KERNEL_C_FLAGS += -fno-stack-protector -fno-builtin-function
KERNEL_C_FLAGS += -fno-builtin -masm=intel -c

emulate: build
	qemu-system-x86_64 -drive format=raw,file=bin/henryOS.bin,if=ide,index=0,media=disk

hexdump: build
	xxd ./bin/henryOS.bin

build: dirs bootsector kernel
	cat ./arch/x86_64/bootsector.o ./bin/kernel.bin > ./bin/henryOS.bin

dirs:
	mkdir -p bin/

%.o: %.c
	$(CC) $(KERNEL_C_FLAGS) $< -o $@

%.o: %.asm
	nasm -f bin $< -o $@

bootsector: arch/x86_64/bootsector.o

kernel: $(KERNEL_C_OBJS)
	$(LD) -m elf_i386 -o ./bin/kernel.bin $^ --oformat=binary -Tkernel/link.ld
	dd if=/dev/zero bs=1 count=512 >> ./bin/kernel.bin

clean:
	find . -name "*.o" -type f -delete
