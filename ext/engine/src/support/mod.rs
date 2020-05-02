//! Corresponds to `Engine::Support`.

pub mod signature_ext;

pub fn initialize() {
    signature_ext::initialize();
}
