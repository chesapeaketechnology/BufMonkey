# BufMonkey
Protobuf support for Garmin's Monkey C programming language 

Unsupported Features
 * `Maps` can be used with a [workaround](https://developers.google.com/protocol-buffers/docs/proto3#backwards-compatibility)
 * `Extensions` and `Services` are currently not supported
 * Unknown fields are dropped
 * `OneOf` is not supported (yet)
 * Currently only decoding messages has been implemented
 
 ## Runtime Library
 The BufMonkey runtime library is a barrel file that can be included into your
 project in the same way that other barrels are included
 
 <details>
 <summary><b>Manually</b></summary><p>
 Download the [BufMonkey barrel]() and drop it into your barrels folder of your Garmin
 application project. Update your jungle file to reference the barrel.
 </p>
 </details>
 
 <details>
 <summary><b>Eclipse</b></summary><p>
 
 Download the [BufMonkey barrel]() or clone this repo and follow the instructions
 for "How to include Barrels" on the [Garmin Website](https://developer.garmin.com/connect-iq/programmers-guide/shareable-libraries).
 </p>
 </details>
 
 <details>
 <summary><b>Gradle-Garmin plugin</b></summary><p>
 Barrels can be easily added to a project that use the [gradle-garmin plugin](https://github.com/chesapeaketechnology/gradle-garmin).
 Add the plugin to your gradle script and then reference the barrel using standard artifact notation as described in
 the [Barrel Dependencies](https://github.com/chesapeaketechnology/gradle-garmin#barrel-dependencies) section:
 
 ```groovy
dependencies {
    barrel "com.test:my-awesome-barrel:1.0.0@barrel"
}
```
 </p>
 </details>

## Generating Messages

<details>
<summary>Manual Generation</summary><p>

* Download an appropriate [protoc.exe](https://repo1.maven.org/maven2/com/google/protobuf/protoc/) and add the directory to the `$PATH`
* Download [protoc-gen-bufmonkey]() and extract the files into the same directory or somewhere else on the `$PATH`.
  * Running the plugin requires Java8 or higher to be installed
  * Protoc does have an option to define a plugin path, but it does not seem to work with the wrapper scripts
* Call `protoc` with `--bufmonkey_out=./path/to/generate`

</p></details>

<details>
<summary>Protobuf Gradle Plugin</summary><p>

* [Add the plugin to your project](https://github.com/google/protobuf-gradle-plugin#adding-the-plugin-to-your-project)
* Configure the plugin to use the BufMonkey code generator plugin
```groovy
protobuf {
  ...
  // Locate the codegen plugins
  plugins {
    // Locate a plugin with name 'bufmonkey'. This step is optional.
    // If you don't locate it, protoc will try to use "protoc-gen-bufmonkey" from
    // system search path.
    bufmonkey {
      artifact = 'com.chesapeaketechnology:bufmonkey-generator:0.1.0'
      // or
      // path = 'tools/bufmonkey-generator'
    }
    // Any other plugins
    ...
  }
  ...
}
```
</p></details>

## Usage

### Import
Import your generated classes module to your Monkey c class:
```java
using BufMonkey.com.test;
```
Notes:
* Class module path is controlled by the package path defined in your proto file
* All generated classes will be generated under the `BufMonkey` namespace.

### Decoding
Decoding Protobuf messages is as simple as creating the type you want to deserialize to
and then passing the protobuf byte array to the `decode` method.
```java
using BufMonkey.com.test;

...

function myMethod(bytes) {
    var generated = new test.MyGeneratedClass();
    generated.decode(bytes);
}

...
```