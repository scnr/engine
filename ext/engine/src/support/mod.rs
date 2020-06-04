//! Corresponds to `Engine::Support`.

pub mod signature;

pub fn initialize() {
    signature::initialize();
}
