//! Corresponds to `Engine::Element`.

pub mod header;
pub mod cookie;

use magnus::Error;

pub fn initialize() -> Result<(), Error> {
    header::initialize()?;
    cookie::initialize()?;
    Ok(())
}
