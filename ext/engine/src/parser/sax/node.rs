use std::iter;
use std::ops::Deref;
use std::rc::{Rc, Weak};
use std::cell::RefCell;

use html5ever::{LocalName, Attribute};

pub type WeakHandle = Weak<RefCell<Node>>;

const TO_HTML_DOCTYPE:        &str = "<!DOCTYPE html>";
const TO_HTML_ATTR_OPEN:      &str = "=\"";
const TO_HTML_DQUOTE_ESCAPE:  &str = "\\\"";
const TO_HTML_TAG_SELF_CLOSE: &str = " />";
const TO_HTML_CLOSE_TAG_OPEN: &str = "</";
const TO_HTML_COMMENT_OPEN:   &str = "<!-- ";
const TO_HTML_COMMENT_CLOSE:  &str = " -->";

const TO_HTML_OPEN_TAG_OPEN: char = '<';
const TO_HTML_TAG_CLOSE:     char = '>';
const TO_HTML_SPACE:         char = ' ';
const TO_HTML_NEWLINE:       char = '\n';
const TO_HTML_ATTR_CLOSE:    char = '"';
const TO_HTML_DQUOTE:        char = TO_HTML_ATTR_CLOSE;

#[derive(Clone, Debug)]
pub struct Handle( pub Rc<RefCell<Node>> );
impl Deref for Handle {
    type Target = Rc<RefCell<Node>>;
    fn deref( &self ) -> &Rc<RefCell<Node>> { &self.0 }
}
impl Handle {
    pub fn to_html( &self, indentation: usize, level: usize ) -> String {
        let mut html = String::new();
        let indent   = &iter::repeat( TO_HTML_SPACE ).take( indentation * level ).collect::<String>();

        let borrowed = &self.borrow();

        match &borrowed.node {
            &Enum::Document =>{
                html.push_str( TO_HTML_DOCTYPE );
                html.push( TO_HTML_NEWLINE );

                for handle in &borrowed.children {
                    html.push_str( &handle.to_html( indentation, level ) );
                }

                html.push( TO_HTML_NEWLINE );
            }

            &Enum::Element { ref name, ref attributes, self_closing } =>{
                html.push_str( indent );
                html.push( TO_HTML_OPEN_TAG_OPEN );
                html.push_str( name );

                for attribute in attributes {
                    html.push( TO_HTML_SPACE );
                    html.push_str( &attribute.name.local );
                    html.push_str( TO_HTML_ATTR_OPEN );
                    html.push_str( &attribute.value.replace( TO_HTML_DQUOTE, TO_HTML_DQUOTE_ESCAPE ) );
                    html.push( TO_HTML_ATTR_CLOSE );
                }

                if self_closing {
                    html.push_str( TO_HTML_TAG_SELF_CLOSE );
                    html.push( TO_HTML_NEWLINE );
                    return html
                }

                html.push( TO_HTML_TAG_CLOSE );
                html.push( TO_HTML_NEWLINE );

                for handle in &borrowed.children {
                    html.push_str( &handle.to_html( indentation, level + 1 ) );
                }

                html.push_str( indent );
                html.push_str( TO_HTML_CLOSE_TAG_OPEN );
                html.push_str( name );
                html.push( TO_HTML_TAG_CLOSE );
                html.push( TO_HTML_NEWLINE );
            }

            &Enum::Text(ref text ) => {
                html.push_str( indent );
                html.push_str( text );
                html.push( TO_HTML_NEWLINE );
            }

            &Enum::Comment(ref text ) => {
                html.push_str( indent );
                html.push_str( TO_HTML_COMMENT_OPEN );
                html.push_str( text );
                html.push_str( TO_HTML_COMMENT_CLOSE );
                html.push( TO_HTML_NEWLINE );
            }
        }

        html
    }

    pub fn nodes_by_name<F>( &self, tag_name: &str, cb: F ) where F: Fn( &Handle ) {
        let ln = tag_name.to_lowercase();

        self.traverse( |handle| {
            if let Enum::Element { ref name, .. } = handle.borrow().node {
                if name.to_string().to_lowercase()  != ln { return }
                cb( handle )
            }
        })
    }

    pub fn nodes_by_attribute_name_and_value<F>( &self, n: &str, v: &str, cb: F )
        where F: Fn( &Handle ) {

        let ln = n.to_lowercase();
        let lv = v.to_lowercase();

        self.traverse( |handle| {
            if let Enum::Element { ref attributes, .. } = handle.borrow().node {
                for attribute in attributes {
                    if attribute.name.local.to_lowercase() == ln &&
                        attribute.value.to_lowercase() == lv {

                        cb( handle );
                        return
                    }
                }
            }
        })
    }

    pub fn text( &self ) -> String {
        let borrowed = &self.borrow();

        match &borrowed.node {
            &Enum::Text( ref text ) | &Enum::Comment( ref text ) => text.clone(),
            &Enum::Element {..} => {
                if !borrowed.children.is_empty() {
                    return borrowed.children[0].text().clone()
                }

                String::new()
            },
            _ => String::new()
        }
    }

    pub fn traverse_comments<F>( &self, cb: F ) where F: Fn( &Handle ) {
        self.traverse( |handle| {
            if let Enum::Comment( .. ) = handle.borrow().node {
                cb( handle )
            }
        })
    }

    pub fn traverse<F>( &self, cb: F ) where F: Fn( &Handle ) {
        Handle::traverser( &self.borrow().children, &cb )
    }

    fn traverser<F>( children: &[Handle], cb: &F ) where F: Fn( &Handle ) {
        for handle in children {
            cb( handle );
            Handle::traverser( &handle.borrow().children, cb );
        }
    }
}

/// The different kinds of nodes in the DOM.
#[derive(Debug)]
pub enum Enum {
    /// The `Document` itself.
    Document,

    /// A text node.
    Text( String ),

    /// A comment.
    Comment( String ),

    /// An element with attributes.
    Element { name: LocalName, attributes: Vec<Attribute>, self_closing: bool }
}

#[derive(Debug)]
pub struct Node {
    pub node:     Enum,
    pub parent:   Option<WeakHandle>,
    pub children: Vec<Handle>
}

impl Node {
    pub fn new_handle(
        node:   Enum,
        parent: Option<WeakHandle>
    ) -> Handle {
        Handle( Rc::new( RefCell::new( Node {
            node:     node,
            parent:   parent,
            children: vec![]
        })))
    }
}
