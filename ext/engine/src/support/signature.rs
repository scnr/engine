//! Corresponds to `Engine::Support::SignatureExt`.

use regex::Regex;

use std::hash::{Hash, Hasher};
// We'll be hashing lots of words and integers and FnvHasher is best for short data.
use fnv::FnvHasher;

use std::collections::BTreeSet;
use std::panic;
use rutie::{Array, Class, Fixnum, Object, RString, AnyObject, Boolean, Float};

lazy_static! {
    static ref TOKENIZE_REGEXP:Regex = Regex::new( r"\W" ).unwrap();
}

fn hash_obj<T: Hash>(t: &T) -> u64 {
    let mut hasher = FnvHasher::default();
    t.hash( &mut hasher );
    hasher.finish()
}

/// Breaks the given string to an array of tokens (integers for efficiency).
fn tokenize( data: &str ) -> BTreeSet<i16> {

    // Can panic when passed binary data instead of valid UTF-8.
    let result = panic::catch_unwind(|| {
        let mut set = BTreeSet::new();

        // Convert to integer hashes and deduplicate.
        for entry in TOKENIZE_REGEXP.split( data ) {
            if entry.is_empty() { continue }

            // We want small hashes for the tokenization to keep RAM usage low
            // so cast down, collisions don't matter since they'll be identical
            // across similar data.
            set.insert( hash_obj( &entry.as_bytes() ) as i16 );
        };

        set
    });

    // Panicked, unfortunately, so we must be dealing with binary data.
    if result.is_err() {
        let mut set = BTreeSet::new();
        for byte in data.as_bytes() {
            set.insert( i16::from( *byte ) );
        }
        return set
    }

    result.unwrap()
}

#[derive(Hash)]
#[derive(PartialEq)]
pub struct Signature {
    tokens: BTreeSet<i16>
}

impl Signature {

    fn new( data: &str ) -> Self {
        Signature {
            tokens: tokenize( data )
        }
    }

    fn refine( &self, other: &Signature ) -> Signature {
        let mut intersection = BTreeSet::new();

        for token in self.tokens.intersection( &other.tokens ).cloned() {
            intersection.insert( token );
        }

        Signature { tokens: intersection }
    }

    fn refine_bang( &mut self, other: &Signature ) -> &mut Signature {
        let tokens           = self.tokens.clone();
        let mut intersection = BTreeSet::new();

        for token in tokens.intersection( &other.tokens ).cloned() {
            intersection.insert( token );
        }

        self.tokens = intersection;

        self
    }

    fn push( &mut self, data: &str ) -> &mut Signature {
        for entry in TOKENIZE_REGEXP.split( data ) {
            if entry.is_empty() { continue }

            // We want small hashes for the tokenization to keep RAM usage low
            // so cast down, collisions don't matter since they'll be identical
            // across similar data.
            self.tokens.insert( hash_obj( &entry.as_bytes() ) as i16 );
        }

        self
    }

    fn differences( &self, other: &Signature ) -> f64 {
        let diff_size  = self.tokens.symmetric_difference( &other.tokens ).count();
        let union_size = self.tokens.union( &other.tokens ).count();

        (diff_size as f64) / (union_size as f64)
    }

    fn is_similar( &self, other: &Signature, threshold: f64 ) -> bool {
        self == other || self.differences( other ) <= threshold
    }

    fn dup( &self ) -> Signature {
        Signature {
            tokens: self.tokens.clone()
        }
    }

    fn is_empty( &self ) -> bool {
        self.tokens.is_empty()
    }

    fn clear( &mut self ) {
        self.tokens.clear();
    }

    fn size( &mut self ) -> i64 {
        self.tokens.len() as i64
    }

    fn ahash( &self ) -> u64 {
        hash_obj( &self.tokens )
    }

    fn inspect( &self ) -> String {
        format!( "Signature {:?}", self.tokens )
    }

}

fn _signature_new_ext( data: &RString ) -> AnyObject {
    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).get_nested_class( "Support" ).
        get_nested_class( "SignatureExt" ).wrap_data(
        Signature::new( data.to_str_unchecked() ), &*SIGNATURE_WRAPPER
    )
}

fn _signature_is_similar_ext( _itself: &SignatureExt, other: &AnyObject, threshold: &Float ) -> Boolean {
    let self_sig  = _itself.get_data( &*SIGNATURE_WRAPPER );
    let other_sig = other.get_data( &*SIGNATURE_WRAPPER );

    Boolean::new( self_sig.is_similar( other_sig, threshold.to_f64() ) )
}

fn _signature_differences_ext( _itself: &SignatureExt, other: &AnyObject ) -> Float {
    let self_sig  = _itself.get_data( &*SIGNATURE_WRAPPER );
    let other_sig = other.get_data( &*SIGNATURE_WRAPPER );

    Float::new( self_sig.differences( other_sig ) )
}

fn _signature_push_ext( _itself: &mut SignatureExt, data: &RString ) -> AnyObject {
    _itself.get_data_mut( &*SIGNATURE_WRAPPER ).push( data.to_str_unchecked() );
    _itself.to_any_object()
}

fn _signature_refine_bang_ext( _itself: &mut SignatureExt, other: &AnyObject ) -> AnyObject {
    _itself.get_data_mut( &*SIGNATURE_WRAPPER ).refine_bang(
            other.get_data( &*SIGNATURE_WRAPPER )
    );
    _itself.to_any_object()
}

fn _signature_refine_ext( _itself: &SignatureExt, other: &AnyObject ) -> AnyObject {
    let self_sig  = _itself.get_data( &*SIGNATURE_WRAPPER );
    let other_sig = other.get_data( &*SIGNATURE_WRAPPER );

    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).get_nested_class( "Support" ).
        get_nested_class( "SignatureExt" ).wrap_data(
            self_sig.refine( other_sig ), &*SIGNATURE_WRAPPER
        )
}

wrappable_struct!( Signature, SignatureWrapper, SIGNATURE_WRAPPER );

class!( SignatureExt );
unsafe_methods!(
    SignatureExt,
    _itself,

    fn signature_new_ext( data: RString ) -> AnyObject {
        _signature_new_ext( &data )
    }

    fn signature_clear_ext() -> AnyObject {
        _itself.get_data_mut( &*SIGNATURE_WRAPPER ).clear();
        _itself.to_any_object()
    }

    fn signature_size_ext() -> Fixnum {
        Fixnum::new( _itself.get_data_mut( &*SIGNATURE_WRAPPER ).size() )
    }

    fn signature_tokens_ext() -> Array {
        let mut array = Array::new();

        for token in _itself.get_data( &*SIGNATURE_WRAPPER ).tokens.clone() {
            array.push( Fixnum::new( i64::from( token ) ) );
        }

        array
    }

    fn signature_dup_ext() -> AnyObject {
        Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).get_nested_class( "Support" ).
            get_nested_class( "SignatureExt" ).wrap_data(
                _itself.get_data( &*SIGNATURE_WRAPPER ).dup(),
                &*SIGNATURE_WRAPPER
            )
    }

    fn signature_refine_ext( other: AnyObject ) -> AnyObject {
        _signature_refine_ext( &_itself, &other )
    }

    fn signature_refine_bang_ext( other: AnyObject ) -> AnyObject {
        _signature_refine_bang_ext( &mut _itself, &other )
    }

    fn signature_push_ext( data: RString ) -> AnyObject {
        _signature_push_ext( &mut _itself, &data )
    }

    fn signature_differences_ext( other: AnyObject ) -> Float {
        _signature_differences_ext( &_itself, &other )
    }

    fn signature_is_similar_ext( other: AnyObject, threshold: Float ) -> Boolean {
        _signature_is_similar_ext( &_itself, &other, &threshold )
    }

    fn signature_is_equal_ext( other: AnyObject ) -> Boolean {
        Boolean::new(
            _itself.get_data( &*SIGNATURE_WRAPPER ) ==
                other.get_data( &*SIGNATURE_WRAPPER )
        )
    }

    fn signature_hash_ext() -> Fixnum {
        Fixnum::new( _itself.get_data( &*SIGNATURE_WRAPPER ).ahash() as i64 )
    }

    fn signature_is_empty_ext() -> Boolean {
        Boolean::new(
            _itself.get_data( &*SIGNATURE_WRAPPER ).is_empty()
        )
    }

    fn signature_inspect_ext() -> RString {
        RString::new_utf8( &_itself.get_data( &*SIGNATURE_WRAPPER ).inspect() )
    }
);

pub fn initialize() {
    Class::from_existing( "SCNR" ).get_nested_class( "Engine" ).
        define_nested_class( "Rust", None ).
        define_nested_class( "Support", None ).
        define_nested_class(
        "Signature",
        None
    ).define( |_itself| {

        _itself.def_self( "new", signature_new_ext );

        _itself.def( "clear", signature_clear_ext );
        _itself.def( "size", signature_size_ext );
        _itself.def( "refine", signature_refine_ext );
        _itself.def( "refine!", signature_refine_bang_ext );
        _itself.def( "differences", signature_differences_ext );
        _itself.def( "tokens", signature_tokens_ext );
        _itself.def( "similar?", signature_is_similar_ext );
        _itself.def( "empty?", signature_is_empty_ext );
        _itself.def( "dup", signature_dup_ext );
        _itself.def( "==", signature_is_equal_ext );
        _itself.def( "<<", signature_push_ext );
        _itself.def( "hash", signature_hash_ext );
        _itself.def( "inspect", signature_inspect_ext );

    });
}
