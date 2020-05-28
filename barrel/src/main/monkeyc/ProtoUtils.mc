using Toybox.Lang;

module BufMonkey {
    /**
    * Utility class that provides useful Protobuf functions.
    */
    class ProtoUtils {
        /**
        * Parses the protobuf header information from a protobuf header byte.
        */
		static function parseProtoHeader(byte, typeDictionary) {
			if(byte != null) {
				if(byte > MSB - 1) {

			    	var strippedFirst = byte^MSB;
			    	byte = strippedFirst;
			    }

			    var wireType = byte & LAST_THREE;
			    var fieldNum = byte >> 3;
			    var fieldType = typeDictionary[fieldNum][0];

			    return new ProtoHeader(wireType, fieldNum, fieldType);
			}

			return null;
		}

        /**
        * Reads an unsigned integer in little endian format
        */
		static function readUintLE(buf, pos) {
        	return buf.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {:offset => pos, :endianness => Lang.ENDIAN_LITTLE});
		}

        /**
        * Reads an unsigned integer in big endian format
        */
		static function readUintBE(buf, pos) {
		    return buf.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {:offset => pos, :endianness => Lang.ENDIAN_BIG});
		}

        /**
        * Reads a signed integer in little endian format
        */
		static function readSintLE(buf, pos) {
        	return buf.decodeNumber(Lang.NUMBER_FORMAT_SINT32, {:offset => pos, :endianness => Lang.ENDIAN_LITTLE});
		}

        /**
        * Reads an signed integer in big endian format
        */
		static function readSintBE(buf, pos) {
		    return buf.decodeNumber(Lang.NUMBER_FORMAT_SINT32, {:offset => pos, :endianness => Lang.ENDIAN_BIG});
		}

        /**
        * Prints the String bit value of the provided value
        */
		static function get_byte_as_bits(val) {
	      var bits = "";
		  for (var i = 7; 0 <= i; i--) {
		  	var bit = (val & (1 << i)) ? '1' : '0';
		    bits += bit;
		  }

		  return bits;
		}

        /**
        * Returns the protobuf wire format value based on the type string.
        */
		static function getWireTypeForFieldType(fieldType) {
			switch(fieldType) {
				case "sint32":
				case "int32":
				case "uint32":
				case "int64":
				case "uint64":
				case "sint64":
				case "bool":
				case "enum":
					return 0;
				case "double":
				case "fixed64":
				case "sfixed64":
					return 1;
				case "string":
				case "bytes":
				case "embedded":
				case "repeated":
					return 2;
				case "float":
				case "fixed32":
				case "sfixed32":
					return 5;
				default:
					break;
			}

			return -1;
		}
	}
}