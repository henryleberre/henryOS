
void kernel_main()
{
        unsigned char* dst = 0xA0000;
        *(dst)=0xCC;
        *(dst+100)=0xCC;
        *(dst+1000)=0xCC;

        __asm__("cli;");
        __asm__("hlt;");

        return;
}

/*

void kernel_isr_unknown() {

}*/