//! Corresponds to extensions to Ruby's STD lib classes.

pub mod string;

use magnus::Error;

pub fn initialize() -> Result<(), Error> {
    string::initialize()
}
