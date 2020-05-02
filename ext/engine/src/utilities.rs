//! Corresponds to `Engine::Utilities`.

use ruru::{Class, Object, RString};
use std::char;

const B10:        char = '#';
const SEMICOLON:  char = ';';
const AMP_SIGN:   char = '&';
const LT_SIGN:    char = '<';
const GT_SIGN:    char = '>';
const APOS_SIGN:  char = '\'';
const QUOTE_SIGN: char = '"';

const QUOT:  &str = "quot";
const APOS:  &str = "apos";
const GT:    &str = "gt";
const LT:    &str = "lt";
const AMP:   &str = "amp";
const HEX:   &str = "#x";

/// Decodes HTML entities in `input`.
///
/// _Corresponds to `Engine::Utilities#html_decode_ext`._
///
/// [Reference](https://vtduncan.github.io/rust-atom/src/xml/lib.rs.html#55)
pub fn html_decode( input: &str ) -> String {
    let mut result = String::with_capacity( input.len() );

    let mut it = input.split( AMP_SIGN );

    // Push everything before the first '&'
    if let Some(sub) = it.next() {
        result.push_str( sub );
    }

    for sub in it {
        match sub.find( SEMICOLON ) {
            Some( idx ) => {
                let ent = &sub[..idx];
                match ent {
                    QUOT => result.push( QUOTE_SIGN ),
                    APOS => result.push( APOS_SIGN ),
                    GT   => result.push( GT_SIGN ),
                    LT   => result.push( LT_SIGN ),
                    AMP  => result.push( AMP_SIGN ),
                    ent => {
                        let val = if ent.starts_with( HEX ) {
                            u32::from_str_radix( &ent[2..], 16 ).ok()
                        } else if ent.starts_with( B10 ) {
                            u32::from_str_radix( &ent[1..], 10 ).ok()
                        } else {
                            None
                        };

                        match val.and_then( char::from_u32 ) {
                            Some(c) => result.push(c),
                            None    => result.push_str( ent )
                        }
                    }
                }
                result.push_str( &sub[idx+1..] );
            }
            None => {
                result.push( AMP_SIGN );
                result.push_str( sub );
                continue
            }
        }
    }

    result
}

class!( Utilities );
unsafe_methods!(
    Utilities,
    _itself,

    fn html_decode_ext( input: RString ) -> RString {
        RString::new( &html_decode( input.to_str_unchecked() ) )
    }

);

/// Adds Ruby hooks for:
///
/// * `Engine::Utilities#html_decode_ext`
pub extern fn initialize() {

    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        get_nested_class( "Utilities" ).define( |itself| {

        itself.def( "html_decode_ext", html_decode_ext );

    });

}
