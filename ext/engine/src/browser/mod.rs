//! Corresponds to `Engine::Browser`.

pub mod parts;

use magnus::Error;

pub fn initialize() -> Result<(), Error> {
    parts::initialize()
}
