//! Corresponds to `Engine::Parser`.

pub mod sax;
pub mod document;

use magnus::Error;

pub fn initialize() -> Result<(), Error> {
    document::initialize()
}
