mkdir -p bin/
rm -rf ./bin/*.bin
rm -rf ./bin/*.o
nasm -f bin ./bootsector.asm -o bin/bootsector.bin
