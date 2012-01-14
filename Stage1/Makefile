lsc64.fd: bootrec lsc.sys
	dd if=/dev/zero of=lsc64.fd bs=512 count=2880
	dd if=bootrec   of=lsc64.fd bs=512 count=1 conv=notrunc
	dd if=lsc.sys   of=lsc64.fd bs=512 seek=1  conv=notrunc

bootrec: bootrec.o
	ld -T bootrec.ld -o bootrec bootrec.o

bootrec.o: bootrec.s
	as -o bootrec.o bootrec.s

lsc.sys: start16.o start64.o lsc_io.o prog.o
	ld -T lsc64.ld -o lsc.sys start16.o start64.o lsc_io.o prog.o

start16.o: start16.s
	as --64 -o start16.o start16.s

start64.o: start64.s
	as --64 -o start64.o start64.s

lsc_io.o: lsc_io.c
	gcc -m64 -ffreestanding -mno-red-zone -c -o lsc_io.o lsc_io.c

prog.o: prog.c
	gcc -m64 -ffreestanding -mno-red-zone -c -o prog.o prog.c

clean:
	rm -f lsc64.fd bootrec lsc.sys *.o parport.out debugger.out bochsout.txt
