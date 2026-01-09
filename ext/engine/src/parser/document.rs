use magnus::{class, method, function, Error, RClass, RModule, Value, RHash, Symbol, TypedData, block::Proc};
use parser::sax::*;
use std::collections::HashMap;

lazy_static! {
    static ref DOCUMENT: String = "document".to_string();
    static ref ELEMENT:  String = "element".to_string();
    static ref TEXT:     String = "text".to_string();
    static ref COMMENT:  String = "comment".to_string();
}

#[magnus::wrap(class = "SCNR::Engine::Rust::Parser::Node", free_immediately, size)]
pub struct Node {
    pub native: Option<node::Handle>
}

impl Node {
    fn new( native: Option<node::Handle> ) -> Self {
        Node {
            native: native
        }
    }

    pub fn name( &self ) -> String {
        if let Some( ref handle ) = self.native {
            if let node::Enum::Element { ref name, .. } = handle.borrow().node {
                return name.to_string()
            }
            return String::new()
        }

        panic!( "Use after free." );
    }

    pub fn attributes( &self ) -> HashMap<String, String> {
        let mut hash = HashMap::new();

        if let Some( ref handle ) = self.native {
            if let node::Enum::Element { ref attributes, .. } = handle.borrow().node {
                for attribute in attributes {
                    hash.insert(
                        attribute.name.local.to_lowercase().to_string(),
                        attribute.value.to_string()
                    );
                }
            }
        } else {
            panic!( "Use after free." );
        }

        hash
    }

    pub fn kind( &self ) -> &String {
        if let Some( ref handle ) = self.native {
            return match handle.borrow().node {
                node::Enum::Document => {
                    &*DOCUMENT
                }

                node::Enum::Element { .. } => {
                    &*ELEMENT
                }

                node::Enum::Text( .. ) => {
                    &*TEXT
                }

                node::Enum::Comment( .. ) => {
                    &*COMMENT
                }
            }
        }

        panic!( "Use after free." );
    }

    pub fn parent( &self ) -> Result<Node, String> {
        if let Some( ref handle ) = self.native {
            let cloned     = handle.clone();
            let parent_ref = &cloned.borrow().parent;
            let cloned_parent_ref = parent_ref.clone();

            if let Some( ref parent_handle ) = cloned_parent_ref {
                return Ok(Node::new(Some(node::Handle(parent_handle.upgrade().unwrap()))));
            } else {
                return Err("Node has no parent, is it the root?".to_string());
            }
        } else {
            return Err("Use after free.".to_string());
        }
    }

    pub fn is_root( &self ) -> bool {
        if let Some( ref handle ) = self.native {
            return handle.borrow().parent.is_none()
        }

        panic!( "Use after free." );
    }

    pub fn nodes_by_name( &self, tag_name: &str, cb: Proc ) {
        if let Some( ref handle ) = self.native {
            handle.nodes_by_name( tag_name, |h| {
                let node = Node::new(Some(h.clone()));
                let _ = cb.call::<(Node,), Value>((node,));
            });
            return
        }

        panic!( "Use after free." );
    }

    pub fn nodes_by_attribute_name_and_value( &self, n: &str, v: &str, cb: Proc ) {
        if let Some( ref handle ) = self.native {
            handle.nodes_by_attribute_name_and_value( n, v, |h| {
                let node = Node::new(Some(h.clone()));
                let _ = cb.call::<(Node,), Value>((node,));
            });
            return
        }

        panic!( "Use after free." );
    }

    pub fn traverse_comments( &self, cb: Proc ) {
        if let Some( ref handle ) = self.native {
            handle.traverse_comments( |h| {
                let node = Node::new(Some(h.clone()));
                let _ = cb.call::<(Node,), Value>((node,));
            });
            return
        }

        panic!( "Use after free." );
    }

    pub fn traverse( &self, cb: Proc ) {
        if let Some( ref handle ) = self.native {
            handle.traverse( |h| {
                let node = Node::new(Some(h.clone()));
                let _ = cb.call::<(Node,), Value>((node,));
            });
            return
        }

        panic!( "Use after free." );
    }

    pub fn text( &self ) -> String {
        if let Some( ref handle ) = self.native {
            return handle.text()
        }

        panic!( "Use after free." );
    }

    pub fn to_html( &self, indentation: usize, level: usize ) -> String {
        if let Some( ref handle ) = self.native {
            return handle.to_html( indentation, level )
        }

        panic!( "Use after free." );
    }

    pub fn free( &mut self ) {
        self.native = None;
    }
}

fn parse(html: String, filter: bool) -> Node {
    Node::new(
        Some(parser::parse(&html, filter))
    )
}

fn node_traverse_comments(rb_self: &Node, cb: Proc) -> bool {
    rb_self.traverse_comments(cb);
    true
}

fn node_nodes_by_name(rb_self: &Node, name: String, cb: Proc) -> bool {
    rb_self.nodes_by_name(&name, cb);
    true
}

fn node_nodes_by_attribute_name_and_value(rb_self: &Node, name: String, value: String, cb: Proc) -> bool {
    rb_self.nodes_by_attribute_name_and_value(&name, &value, cb);
    true
}

fn node_traverse(rb_self: &Node, cb: Proc) -> bool {
    rb_self.traverse(cb);
    true
}

fn node_is_root(rb_self: &Node) -> bool {
    rb_self.is_root()
}

fn node_text(rb_self: &Node) -> String {
    rb_self.text()
}

fn node_name(rb_self: &Node) -> Symbol {
    Symbol::new(&rb_self.name())
}

fn node_attributes(rb_self: &Node) -> HashMap<String, String> {
    rb_self.attributes()
}

fn node_kind(rb_self: &Node) -> Symbol {
    Symbol::new(rb_self.kind())
}

fn node_parent(rb_self: &Node) -> Result<Node, Error> {
    match rb_self.parent() {
        Ok(node) => Ok(node),
        Err(msg) => Err(Error::new(magnus::exception::runtime_error(), msg))
    }
}

fn node_free(rb_self: &Node) -> bool {
    unsafe {
        let ptr = rb_self as *const Node as *mut Node;
        (*ptr).free();
    }
    true
}

fn node_to_html(rb_self: &Node) -> String {
    if let Some(ref handle) = rb_self.native {
        handle.to_html(4, 0)
    } else {
        String::new()
    }
}

pub fn initialize() -> Result<(), Error> {
    let scnr_ns = class::object().const_get::<_, RModule>("SCNR")?;
    let engine_ns = scnr_ns.const_get::<_, RModule>("Engine")?;
    let rust_ns = engine_ns.define_module("Rust")?;
    let parser_ns = rust_ns.define_module("Parser")?;
    let node_class = parser_ns.define_class("Node", class::object())?;

    node_class.define_singleton_method("parse", function!(parse, 2))?;

    node_class.define_method("nodes_by_name", method!(node_nodes_by_name, 2))?;
    node_class.define_method("nodes_by_attribute_name_and_value", method!(node_nodes_by_attribute_name_and_value, 3))?;
    node_class.define_method("traverse_comments", method!(node_traverse_comments, 1))?;
    node_class.define_method("traverse", method!(node_traverse, 1))?;
    node_class.define_method("parent", method!(node_parent, 0))?;
    node_class.define_method("text", method!(node_text, 0))?;
    node_class.define_method("type", method!(node_kind, 0))?;
    node_class.define_method("attributes", method!(node_attributes, 0))?;
    node_class.define_method("name", method!(node_name, 0))?;
    node_class.define_method("root?", method!(node_is_root, 0))?;
    node_class.define_method("free", method!(node_free, 0))?;
    node_class.define_method("to_html", method!(node_to_html, 0))?;

    Ok(())
}
