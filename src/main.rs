#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[panic_handler]
fn on_panic(_info: &PanicInfo) -> ! {
	loop {}
}

#[no_mangle]
extern "C" fn _start() -> ! {
	main();

	loop {}
}

fn main() {
	// TODO: println!("Hello, world!");
}
