//! Corresponds to `Engine::Support::SetExt`.

use std::collections::HashSet;
use magnus::{class, method, function, Error, RClass, RModule, Value, TypedData, prelude::*};

#[derive(PartialEq, Clone)]
#[magnus::wrap(class = "SCNR::Engine::Rust::Support::Filter::Set", free_immediately, size)]
pub struct Set {
    collection: HashSet<i64>
}

impl Set {

    fn new() -> Self {
        Set {
            collection: HashSet::new()
        }
    }

    fn push( &mut self, entry: i64 ) -> &mut Set {
        self.collection.insert( entry );
        self
    }

    fn includes( &self, entry: &i64 ) -> bool {
        self.collection.contains( entry )
    }

    fn dup( &self ) -> Set {
        self.clone()
    }

    fn is_empty( &self ) -> bool {
        self.collection.is_empty()
    }

    fn clear( &mut self ) {
        self.collection.clear();
    }

    fn size( &self ) -> i64 {
        self.collection.len() as i64
    }

    fn inspect( &self ) -> String {
        format!( "Set {:?}", self.collection )
    }

    fn collection_array( &self ) -> Vec<i64> {
        self.collection.iter().cloned().collect()
    }
}

// Magnus method wrappers
fn set_new() -> Set {
    Set::new()
}

fn set_clear(rb_self: &Set) {
    unsafe {
        let ptr = rb_self as *const Set as *mut Set;
        (*ptr).clear();
    }
}

fn set_size(rb_self: &Set) -> i64 {
    rb_self.size()
}

fn set_collection(rb_self: &Set) -> Vec<i64> {
    rb_self.collection_array()
}

fn set_dup(rb_self: &Set) -> Set {
    rb_self.dup()
}

fn set_push(rb_self: &Set, entry: i64) {
    unsafe {
        let ptr = rb_self as *const Set as *mut Set;
        (*ptr).push(entry);
    }
}

fn set_include(rb_self: &Set, entry: i64) -> bool {
    rb_self.includes(&entry)
}

fn set_is_empty(rb_self: &Set) -> bool {
    rb_self.is_empty()
}

fn set_inspect(rb_self: &Set) -> String {
    rb_self.inspect()
}

pub fn initialize() -> Result<(), Error> {
    let scnr_ns = class::object().const_get::<_, RModule>("SCNR")?;
    let engine_ns = scnr_ns.const_get::<_, RModule>("Engine")?;
    let rust_ns = engine_ns.define_module("Rust")?;
    let support_ns = rust_ns.define_module("Support")?;
    let filter_ns = support_ns.define_module("Filter")?;
    let set_class = filter_ns.define_class("Set", class::object())?;

    set_class.define_singleton_method("new", function!(set_new, 0))?;

    set_class.define_method("clear", method!(set_clear, 0))?;
    set_class.define_method("size", method!(set_size, 0))?;
    set_class.define_method("collection", method!(set_collection, 0))?;
    set_class.define_method("empty?", method!(set_is_empty, 0))?;
    set_class.define_method("dup", method!(set_dup, 0))?;
    set_class.define_method("include?", method!(set_include, 1))?;
    set_class.define_method("<<", method!(set_push, 1))?;
    set_class.define_method("inspect", method!(set_inspect, 0))?;

    Ok(())
}
