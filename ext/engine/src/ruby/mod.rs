//! Corresponds to extensions to Ruby's STD lib classes.

pub mod string;

pub fn initialize() {
    string::initialize();
}
