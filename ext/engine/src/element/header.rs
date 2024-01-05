//! Corresponds to `Engine::Header`.

use url::percent_encoding;
use rutie::{Class, Object, RString};

define_encode_set! {
    pub HEADER_ENCODE_SET = [percent_encoding::SIMPLE_ENCODE_SET] | { '\n', '\r' }
}

fn encode( input: &str ) -> String {
    percent_encoding::percent_encode(
        input.as_bytes(),
        HEADER_ENCODE_SET
    ).collect::<String>()
}

class!( Header );
unsafe_methods!(
    Header,
    _itself,

    fn header_encode( string: RString ) -> RString {
        RString::new_utf8( &encode( string.to_str() ) )
    }
);

/// Adds Ruby hooks for:
///
/// * `Engine::Header.encode_ext`
pub fn initialize() {

    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        define_nested_class( "Rust", None ).define_nested_class( "Element", None ).
        define_nested_class( "Header", None ).define( |itself| {

        itself.def_self( "encode_ext", header_encode );

    });

}
