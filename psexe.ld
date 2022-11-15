/* some constants defining our address space */
RAM_BASE    = 0x80000000;            /* this is the start of our main memory segment */
RAM_SIZE    = 2M;                    /* PSX has 2 MiB of RAM */
BIOS_SIZE   = 64K;                   /* PSX reserves the lower 64 KiB of RAM for BIOS/kernel */
HEADER_SIZE = 2K;                    /* PSX EXE files must start with a 2 KiB header */
LOAD_ADDR   = RAM_BASE + BIOS_SIZE;  /* address where our binary will be loaded (0x80010000) */
STACK_INIT  = RAM_BASE + 0x001FFF00; /* the top of our stack (remember, stack grows downwards) */

/* the layout of our memory */
MEMORY {
	HEADER    : ORIGIN = LOAD_ADDR - HEADER_SIZE, LENGTH = HEADER_SIZE
	RAM (rwx) : ORIGIN = LOAD_ADDR, LENGTH = RAM_SIZE - (LOAD_ADDR - RAM_BASE)
}

/* the true entry point of our executable */
ENTRY(_start)

/* here we tell the linker how should the file be filled with data */
SECTIONS {
	/* this is our PSX EXE header */
	.psx_exe_header : {
		/* magic number (ASCII string "PS-X EXE") */
		BYTE(0x50); BYTE(0x53); BYTE(0x2d); BYTE(0x58);
		BYTE(0x20); BYTE(0x45); BYTE(0x58); BYTE(0x45);

		/* 8 unused bytes */
		QUAD(0);

		/* our entry point */
		LONG(ABSOLUTE(_start));

		/* intial value of global pointer (I don't think this is used by Rust) */
		LONG(_gp);

		/* address where our binary gets loaded to */
		LONG(LOAD_ADDR);

		/* number of bytes that should be loaded (after this header) */
		LONG(__bss_start - __text_start);

		/* 16 unused bytes */
		QUAD(0); QUAD(0);

		/* stack base pointer */
		LONG(STACK_INIT);

		/* initial stack offset */
		LONG(0);

		/* 24 unused bytes */
		QUAD(0); QUAD(0); LONG(0);

		/* region indicator (North America, Europe, Japan) */
		KEEP(*(.region));

		/* alignment to 2 KiB */
		. = ALIGN(HEADER_SIZE);
	} > HEADER

	/* here is where our code lives */
	.text : {
		__text_start = .;

		/* our constructors table */
		__ctors_start = .;
		,*(.ctors*)
		__ctors_end = .;
		ASSERT((__ctors_end - __ctors_start) % 4 == 0, "Invalid .ctors section");

		/* our destructors table */
		__dtors_start = .;
		,*(.dtors*)
		__dtors_end = .;
		ASSERT((__dtors_end - __dtors_start) % 4 == 0, "Invalid .dtors section");

		/* the majority of our code */
		,*(.text*)

		__text_end = .;
	} > RAM

	/* this is where all of our static variables, strings, etc. live */
	.data : {
		__data_start = .;
		,*(.data*)
		,*(.rodata*)
		,*(.got)

		/* padding to a multiple of 2K is required for loading from ISO */
		. = ALIGN(2048);
		__data_end = .;
	} > RAM

	/* this is that uninitialized .bss section, I was talking about */
	.bss (NOLOAD) : {
		__bss_start = .;
		,*(.bss*)
		,*(COMMON)
		__bss_end = .;
	} > RAM

	/* make the heap word-aligned */
	. = ALIGN(4);
	__heap_start = .;

	/* drop all sorts of useless metadata */
	/DISCARD/ : {
		,*(.MIPS.abiflags)
		,*(.reginfo)
		,*(.eh_frame_hdr)
		,*(.eh_frame)
	}
}
