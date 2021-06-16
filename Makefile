KERNEL_C_SRCS   = $(wildcard kernel/*.c)
KERNEL_C_OBJS   = $(KERNEL_C_SRCS:.c=.o)

BOOT_ASM_SRCS   = $(wildcard boot/*.asm)
BOOT_ASM_OBJS   = $(BOOT_ASM_SRCS:.asm=.bin)

KERNEL_C_FLAGS  = -m16 -Wno-pointer-arith -Wno-unused-parameter
KERNEL_C_FLAGS += -nostdlib -nostdinc -ffreestanding -fno-pie
KERNEL_C_FLAGS += -fno-stack-protector -fno-builtin-function
KERNEL_C_FLAGS += -fno-builtin -masm=intel -c -O0

BOOT_TARGET_BIN   = ./bin/boot.bin
KERNEL_TARGET_BIN = ./bin/kernel.bin
OS_TARGET_BIN     = ./bin/henryOS.bin

all: build

dirs:
	mkdir -p bin/

%.o: %.c
	$(CC) $(KERNEL_C_FLAGS) $< -o $@

%.bin: %.asm
	nasm -f bin $< -o $@

bootsector: dirs $(BOOT_ASM_OBJS)
	cp ./boot/bootloader.bin $(BOOT_TARGET_BIN)

kernel: dirs $(KERNEL_C_OBJS)
	$(LD) -m elf_i386 -o $(KERNEL_TARGET_BIN) $(KERNEL_C_OBJS) -Tkernel/kernel.ld --oformat=binary
	dd if=/dev/zero bs=1 count=512 >> $(KERNEL_TARGET_BIN)

build: dirs bootsector kernel
	cat $(BOOT_TARGET_BIN) $(KERNEL_TARGET_BIN) > $(OS_TARGET_BIN)

clean:
	find . -name "*.o"   -type f -delete
	find . -name "*.bin" -type f -delete

emulate: build
	qemu-system-x86_64 -drive format=raw,file=$(OS_TARGET_BIN),if=ide,index=0,media=disk

hexdump: build
	hexdump $(OS_TARGET_BIN)