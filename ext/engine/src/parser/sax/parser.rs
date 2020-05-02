use std::default::Default;

use tendril::ByteTendril;

use html5ever::tokenizer::{BufferQueue, TokenSink, Tokenizer, Token, TokenizerOpts, TokenSinkResult};
use html5ever::tokenizer::{CharacterTokens, NullCharacterToken, TagToken, StartTag, EndTag, CommentToken};

use parser::sax::{handler, node};

struct SAX {
    pub handler: handler::Handler
}

impl TokenSink for SAX {
    type Handle = ();

    fn process_token( &mut self, token: Token, _: u64) -> TokenSinkResult<()> {

        match token {

            CharacterTokens( text ) => {
                let sanitized = text.chars().collect::<String>().trim().to_string();
                if sanitized .is_empty() { return TokenSinkResult::Continue }

                self.handler.text( sanitized  )
            }

            CommentToken( comment ) => {
                let sanitized = comment.chars().collect::<String>().trim().to_string();
                if sanitized .is_empty() { return TokenSinkResult::Continue }

                self.handler.comment( sanitized  )
            },

            NullCharacterToken => {
                self.handler.text( "\0".to_string() )
            },

            TagToken( tag ) => {
                match tag.kind {
                    StartTag => {
                        self.handler.start_element( tag.name, tag.attrs, tag.self_closing );
                    },

                    EndTag   => {
                        if !tag.self_closing {
                            self.handler.end_element( &tag.name )
                        }
                    }
                }
            }

            _ => {
//                println!( "OTHER: {:?}", token );
            }

        }

        TokenSinkResult::Continue
    }
}

pub fn parse( html: &str, filter: bool ) -> node::Handle {
    let root    = node::Node::new_handle( node::Enum::Document, None );
    let handler = handler::Handler::new( root.clone(), filter );
    let sink    = SAX { handler: handler };

    let mut chunk = ByteTendril::new();
    let _ = chunk.try_push_bytes( html.as_bytes());

    let mut input = BufferQueue::new();
    input.push_back( chunk.try_reinterpret().unwrap() );

    let mut tok = Tokenizer::new( sink, TokenizerOpts { .. Default::default() });

    let _ = tok.feed( &mut input );
    assert!( input.is_empty() );
    tok.end();

    root
}
