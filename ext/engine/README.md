# Install Rust

    rustup install nightly
    rustup default nightly

# Build extension

    cargo build --release

## MS Windows

1. Install  Visual C++ Redistributable Packages for Visual Studio 2013: 
    * https://www.microsoft.com/en-us/download/details.aspx?id=40784
2. Download `.lib` file from: 
    * https://github.com/gosu/gosu/tree/master/dependencies/msvcrt-ruby
    * Place it in: `C:\Ruby23-x64\lib`
