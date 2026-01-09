//! Corresponds to `Engine::Cookie`.

use url::percent_encoding;
use magnus::{class, function, Error, RClass, RModule};

define_encode_set! {
    pub COOKIE_ENCODE_SET = [percent_encoding::SIMPLE_ENCODE_SET] | { '+', ';', '%', '\0', '&', ' ', '"', '\n', '\r', '=' }
}

const ENCODED_SPACE: &str = "%20";
const PLUS:          &str = "+";

// Instead of just encoding everything we do this selectively because:
//
//  * Some webapps don't actually decode some cookies, they just get
//    the raw value, so if we encode something may break.
//  * We need to encode spaces as '+' because of the above.
//    Since we decode values, any un-encoded '+' will be converted
//    to spaces, and in order to send back a value that the server
//    expects we use '+' for spaces.
fn encode( input: &str ) -> String {
    percent_encoding::percent_encode(
        input.as_bytes(),
        COOKIE_ENCODE_SET
    ).collect::<String>().replace( ENCODED_SPACE, PLUS )
}

fn cookie_encode(string: String) -> String {
    encode(&string)
}

/// Adds Ruby hooks for:
///
/// * `Engine::Cookie.encode_ext`
pub fn initialize() -> Result<(), Error> {
    let scnr_ns = class::object().const_get::<_, RModule>("SCNR")?;
    let engine_ns = scnr_ns.const_get::<_, RModule>("Engine")?;
    let rust_ns = engine_ns.define_module("Rust")?;
    let element_ns = rust_ns.define_module("Element")?;
    let cookie_class = element_ns.define_class("Cookie", class::object())?;

    cookie_class.define_singleton_method("encode_ext", function!(cookie_encode, 1))?;

    Ok(())
}
