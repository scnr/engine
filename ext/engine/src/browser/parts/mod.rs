//! Corresponds to `Engine::Browser::Parts`.

pub mod http;

use magnus::Error;

pub fn initialize() -> Result<(), Error> {
    http::initialize()
}
