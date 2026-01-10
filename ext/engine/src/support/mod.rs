//! Corresponds to `Engine::Support`.

pub mod signature;
pub mod filter;

use magnus::Error;

pub fn initialize() -> Result<(), Error> {
    signature::initialize()?;
    filter::set::initialize()?;
    Ok(())
}
