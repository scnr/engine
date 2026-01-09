//! Corresponds to `Engine::Header`.

use url::percent_encoding;
use magnus::{class, function, Error, RClass, RModule};

define_encode_set! {
    pub HEADER_ENCODE_SET = [percent_encoding::SIMPLE_ENCODE_SET] | { '\n', '\r' }
}

fn encode( input: &str ) -> String {
    percent_encoding::percent_encode(
        input.as_bytes(),
        HEADER_ENCODE_SET
    ).collect::<String>()
}

fn header_encode(string: String) -> String {
    encode(&string)
}

/// Adds Ruby hooks for:
///
/// * `Engine::Header.encode_ext`
pub fn initialize() -> Result<(), Error> {
    let scnr_ns = class::object().const_get::<_, RModule>("SCNR")?;
    let engine_ns = scnr_ns.const_get::<_, RModule>("Engine")?;
    let rust_ns = engine_ns.define_module("Rust")?;
    let element_ns = rust_ns.define_module("Element")?;
    let header_class = element_ns.define_class("Header", class::object())?;

    header_class.define_singleton_method("encode_ext", function!(header_encode, 1))?;

    Ok(())
}
