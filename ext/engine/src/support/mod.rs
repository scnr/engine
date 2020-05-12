//! Corresponds to `Engine::Support`.

pub mod set;
pub mod signature;

pub fn initialize() {
    set::initialize();
    signature::initialize();
}
