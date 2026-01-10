//! Corresponds to `Engine::Support::SignatureExt`.

use regex::Regex;

use std::hash::{Hash, Hasher};
// We'll be hashing lots of words and integers and FnvHasher is best for short data.
use fnv::FnvHasher;

use std::collections::BTreeSet;
use std::panic;
use magnus::{class, method, function, Error, RClass, RModule, Value, TypedData, typed_data, prelude::*};

lazy_static! {
    static ref TOKENIZE_REGEXP:Regex = Regex::new( r"\W" ).unwrap();
}

fn hash_obj<T: Hash>(t: &T) -> u64 {
    let mut hasher = FnvHasher::default();
    t.hash( &mut hasher );
    hasher.finish()
}

/// Breaks the given string to an array of tokens (integers for efficiency).
fn tokenize( data: String ) -> BTreeSet<i16> {

    // Can panic when passed binary data instead of valid UTF-8.
    let result = panic::catch_unwind(|| {
        let mut set = BTreeSet::new();

        // Convert to integer hashes and deduplicate.
        for entry in TOKENIZE_REGEXP.split( &data ) {
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
#[derive(Clone)]
#[magnus::wrap(class = "SCNR::Engine::Rust::Support::Signature", free_immediately, size)]
pub struct Signature {
    tokens: BTreeSet<i16>
}

impl Signature {

    fn new( data: String ) -> Self {
        Signature {
            tokens: tokenize( data )
        }
    }

    fn refine( &self, other: &Signature ) -> Signature {
        Signature {
            tokens: self.tokens.intersection( &other.tokens ).cloned().collect()
        }
    }

    fn refine_bang( &mut self, other: &Signature ) -> &mut Signature {
        self.tokens = self.tokens.intersection( &other.tokens ).cloned().collect();
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
        self.clone()
    }

    fn is_empty( &self ) -> bool {
        self.tokens.is_empty()
    }

    fn clear( &mut self ) {
        self.tokens.clear();
    }

    fn size( &self ) -> i64 {
        self.tokens.len() as i64
    }

    fn ahash( &self ) -> u64 {
        hash_obj( &self.tokens )
    }

    fn inspect( &self ) -> String {
        format!( "Signature {:?}", self.tokens )
    }

    fn tokens_array( &self ) -> Vec<i64> {
        self.tokens.iter().map(|&t| i64::from(t)).collect()
    }
}

// Magnus method wrappers
fn signature_new(data: String) -> Signature {
    Signature::new(data)
}

fn signature_clear(rb_self: typed_data::Obj<Signature>) -> typed_data::Obj<Signature> {
    // Need to get mutable reference
    unsafe {
        let ptr = &*rb_self as *const Signature as *mut Signature;
        (*ptr).clear();
    }
    rb_self
}

fn signature_size(rb_self: &Signature) -> i64 {
    rb_self.size()
}

fn signature_tokens(rb_self: &Signature) -> Vec<i64> {
    rb_self.tokens_array()
}

fn signature_dup(rb_self: &Signature) -> Signature {
    rb_self.dup()
}

fn signature_refine(rb_self: &Signature, other: Value) -> Result<Signature, Error> {
    // Try to extract Signature from the Value - works with subclasses too
    let other_obj = typed_data::Obj::<Signature>::try_convert(other)?;
    let other_ref: &Signature = &*other_obj;
    Ok(rb_self.refine(other_ref))
}

fn signature_refine_bang(rb_self: typed_data::Obj<Signature>, other: Value) -> Result<typed_data::Obj<Signature>, Error> {
    // Try to extract Signature from the Value - works with subclasses too
    let other_obj = typed_data::Obj::<Signature>::try_convert(other)?;
    let other_ref: &Signature = &*other_obj;
    unsafe {
        let ptr = &*rb_self as *const Signature as *mut Signature;
        (*ptr).refine_bang(other_ref);
    }
    Ok(rb_self)
}

fn signature_push(rb_self: typed_data::Obj<Signature>, data: String) -> typed_data::Obj<Signature> {
    unsafe {
        let ptr = &*rb_self as *const Signature as *mut Signature;
        (*ptr).push(&data);
    }
    rb_self
}

fn signature_differences(rb_self: &Signature, other: Value) -> Result<f64, Error> {
    // Try to extract Signature from the Value - works with subclasses too
    let other_obj = typed_data::Obj::<Signature>::try_convert(other)?;
    let other_ref: &Signature = &*other_obj;
    Ok(rb_self.differences(other_ref))
}

fn signature_is_similar(rb_self: &Signature, other: Value, threshold: f64) -> Result<bool, Error> {
    // Try to extract Signature from the Value - works with subclasses too
    let other_obj = typed_data::Obj::<Signature>::try_convert(other)?;
    let other_ref: &Signature = &*other_obj;
    Ok(rb_self.is_similar(other_ref, threshold))
}

fn signature_is_equal(rb_self: &Signature, other: Value) -> Result<bool, Error> {
    // Try to extract Signature from the Value - works with subclasses too
    let other_obj = typed_data::Obj::<Signature>::try_convert(other)?;
    let other_ref: &Signature = &*other_obj;
    Ok(rb_self == other_ref)
}

fn signature_hash(rb_self: &Signature) -> i64 {
    rb_self.ahash() as i64
}

fn signature_is_empty(rb_self: &Signature) -> bool {
    rb_self.is_empty()
}

fn signature_inspect(rb_self: &Signature) -> String {
    rb_self.inspect()
}

pub fn initialize() -> Result<(), Error> {
    let scnr_ns = class::object().const_get::<_, RModule>("SCNR")?;
    let engine_ns = scnr_ns.const_get::<_, RModule>("Engine")?;
    let rust_ns = engine_ns.define_module("Rust")?;
    let support_ns = rust_ns.define_module("Support")?;
    let sig_class = support_ns.define_class("Signature", class::object())?;

    sig_class.define_singleton_method("new", function!(signature_new, 1))?;

    sig_class.define_method("clear", method!(signature_clear, 0))?;
    sig_class.define_method("size", method!(signature_size, 0))?;
    // Use _ext suffix to avoid conflicts with Ruby wrapper methods that normalize arguments
    sig_class.define_method("refine_ext", method!(signature_refine, 1))?;
    sig_class.define_method("refine_bang_ext", method!(signature_refine_bang, 1))?;
    sig_class.define_method("differences_ext", method!(signature_differences, 1))?;
    sig_class.define_method("tokens", method!(signature_tokens, 0))?;
    sig_class.define_method("is_similar_ext", method!(signature_is_similar, 2))?;
    sig_class.define_method("empty?", method!(signature_is_empty, 0))?;
    sig_class.define_method("dup", method!(signature_dup, 0))?;
    sig_class.define_method("is_equal_ext", method!(signature_is_equal, 1))?;
    sig_class.define_method("<<", method!(signature_push, 1))?;
    sig_class.define_method("hash", method!(signature_hash, 0))?;
    sig_class.define_method("inspect", method!(signature_inspect, 0))?;

    Ok(())
}
