//! Corresponds to `Engine::Browser::Parts::HTTP`.

use url::percent_encoding;
use magnus::{class, function, Error, RClass, RModule};

define_encode_set! {
    pub SEMICOLON_ENCODE_SET = [percent_encoding::SIMPLE_ENCODE_SET] | { ';' }
}

fn encode( input: &str ) -> String {
    percent_encoding::percent_encode(
        input.as_bytes(),
        SEMICOLON_ENCODE_SET
    ).collect::<String>()
}

fn browser_parts_http_encode_semicolon(string: String) -> String {
    encode(&string)
}

/// Adds Ruby hooks for:
///
/// * `SCNR::Engine::Browser::Parts::HTTP.encode_semicolon_ext`
pub fn initialize() -> Result<(), Error> {
    let scnr_ns = class::object().const_get::<_, RModule>("SCNR")?;
    let engine_ns = scnr_ns.const_get::<_, RModule>("Engine")?;
    let rust_ns = engine_ns.define_module("Rust")?;
    let browser_ns = rust_ns.define_module("Browser")?;
    let parts_ns = browser_ns.define_module("Parts")?;
    let http_class = parts_ns.define_class("HTTP", class::object())?;

    http_class.define_singleton_method("encode_semicolon_ext", function!(browser_parts_http_encode_semicolon, 1))?;

    Ok(())
}
