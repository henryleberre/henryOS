all: dirs bootsector

dirs:
	mkdir -p bin/

%.o: %.S
	nasm -f bin $< -o $@

bootsector: arch/x86_64/bootsector.o

clean:
	find . -name "*.o" -type f -delete