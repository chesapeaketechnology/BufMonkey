/**
* BufMonkey module contains classes and utilities to encode and decode protobuf messages into
* POMOs (Plain Old MonkeyC Objects). All Protobuf POMOs extend the BufMonkeyType contained in this
* class which leverages the ProtoEncoding and ProtoDecoding classes for object serialization/deserialization.
*/
module BufMonkey {
    /**
    * Most Significant Bit in a byte
    */
    const MSB = 128;

    /**
    * Maximum numerical value for an unsigned byte
    */
    const MAX_BYTE_VALUE = 255;

    /**
    * 0x0000111 byte value which is useful for grabbing Protobuf header info
    */
    const LAST_THREE = 7;

    /**
    * Infinity definition for floating point calculations
    */
    const INFINITY = 0x7FF0000000000000;

    /**
    * Main class which generated classes extend from to get encoding and decoding functionality.
    */
	class BufMonkeyType {
	        /**
            * ProtoDecoder object which is used to decode Protobuf messages
            */
    		protected var decoder;

    		/**
            * ProtoEncoder object which is used to encode Protobuf messages
            */
    		protected var encoder;

    		function initialize(dict) {
    			decoder = new ProtoDecoder(dict);
    			encoder = new ProtoEncoder(dict);
    		}

            /**
            * The ProtoDecoder class uses this function to pass data to the generated classes. This method
            * should be overriden by child classes to take decoded objects and build out the object.
            */
    		function setValue(position, value) {
    			//to be overriden by subclass
    		}

            /**
            * Method to initiate encoding of the child class to the Protobuf wire format
            */
    		function encode() {
    			encoder.encode(self);
    		}

            /**
            * Method to initiate decoding of a complete Protobuf byte array to a child object
            */
    		function decode(bytes) {
    			decoder.decode(bytes, self);
    		}

    	}
}