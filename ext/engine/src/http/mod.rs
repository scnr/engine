//! Corresponds to `Engine::HTTP`.

pub mod headers;

use magnus::Error;

pub fn initialize() -> Result<(), Error> {
    headers::initialize()
}
