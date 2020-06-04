//! Corresponds to `Engine::Browser::Parts::HTTP`.

use url::percent_encoding;
use rutie::{Class, Object, RString};

define_encode_set! {
    pub SEMICOLON_ENCODE_SET = [percent_encoding::SIMPLE_ENCODE_SET] | { ';' }
}

fn encode( input: &str ) -> String {
    percent_encoding::percent_encode(
        input.as_bytes(),
        SEMICOLON_ENCODE_SET
    ).collect::<String>()
}

class!( BrowserPartsHTTP );
unsafe_methods!(
    BrowserPartsHTTP,
    _itself,

    fn browser_parts_http_encode_semicolon( string: RString ) -> RString {
        RString::new( &encode( string.to_str_unchecked() ) )
    }
);

/// Adds Ruby hooks for:
///
/// * `SCNR::Engine::Browser::Parts::HTTP.encode_semicolon_ext`
pub fn initialize() {

    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        define_nested_class( "Rust", None ).define_nested_class( "Browser", None ).
        define_nested_class( "Parts", None ).
        define_nested_class( "HTTP", None ).define( |itself| {

        itself.def_self( "encode_semicolon_ext", browser_parts_http_encode_semicolon );

    });

}
