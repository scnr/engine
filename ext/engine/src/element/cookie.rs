//! Corresponds to `Engine::Cookie`.

use url::percent_encoding;
use rutie::{Class, Object, RString};

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

class!( Cookie );
unsafe_methods!(
    Cookie,
    _itself,

    fn cookie_encode( string: RString ) -> RString {
        RString::new_utf8( &encode( string.to_str() ) )
    }
);

/// Adds Ruby hooks for:
///
/// * `Engine::Cookie.encode_ext`
pub fn initialize() {

    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        define_nested_class( "Rust", None ).define_nested_class( "Element", None ).
        define_nested_class( "Cookie", None ).define( |itself| {

        itself.def_self( "encode_ext", cookie_encode );

    });

}
