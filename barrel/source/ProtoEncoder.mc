module BufMonkey {
	/*
    * Class for serializing BufMonkeyType Objects into Protobuf messages
    */
    class ProtoEncoder {
    	/*
	    * Dictionary mapping of field numbers with types
	    */
		hidden var memberDict;

		function initialize(dict) {
			memberDict = dict;
		}

		/*
	    * Takes a BufMonkeyType and encodes the object into a protobug byte array
	    */
		function encode(bufMonkeyType) {
			//TODO
		}
	}
}
