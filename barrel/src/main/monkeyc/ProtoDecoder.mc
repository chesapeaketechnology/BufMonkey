using Toybox.StringUtil;
using Toybox.Lang;
using Toybox.System;

module BufMonkey {
    /**
    * Class for deserializing Protobuf messages into a BufMonkeyType object
    */
    class ProtoDecoder {
        /**
        * Dictionary mapping of field numbers with types
        */
		hidden var memberDict;

		/**
        * Current index in the byte array payload
        */
		hidden var currentIndex;

		/**
        * The length of the value that was last parsed
        */
		hidden var lastReadLength;

		function initialize(dict) {
			memberDict = dict;
			currentIndex = 0;
			lastReadLength = 0;
		}

        /**
        * Main decoding method which decodes a provided byte array and passes values
        * to the provided BufMonkeyType.
        *
        */
		function decode(bytes, bufMonkeyType) {
			if(bufMonkeyType != null) {
			    while(currentIndex < bytes.size()) {
				     //strip MSB
				    var protoHeader = ProtoUtils.parseProtoHeader(bytes[currentIndex], memberDict);

				    if(protoHeader != null) {
				    	var fieldVal = getDecodedValue(protoHeader, bytes);

					    if(fieldVal != null) {
					    	bufMonkeyType.setValue(protoHeader.fieldNum, fieldVal);
					    } else {
					    	System.println("Val was null! Unable to set field: " + protoHeader.fieldNum);
					    }
				    } else {
				    	System.println("Unable to parse expected protobuf header!");
				    }

				    currentIndex++;
			    }
		    } else {
		    	System.println("Unable to decode NULL BufMonkeyType!");
		    }
		}

        /**
        * Retrieves a protobuf type value based on the parsed header information.
        */
		private function getDecodedValue(protoHeader, bytes) {
			lastReadLength = 0;

		    var fieldVal = null;

		    switch(protoHeader.wireType) {
		    	case 0:
			    	//varint
			    	fieldVal = parseVarint(protoHeader.fieldType, bytes, currentIndex);
			    	break;
			    case 1:
					//64-bit
			    	fieldVal = parse64Bit(protoHeader.fieldType, bytes.slice(currentIndex + 1, currentIndex + 9));
			    	break;
			    case 2:
			    	//length-delimited
			    	fieldVal = parseLengthDelimited(protoHeader.fieldType, bytes, currentIndex);
			    	break;
			    case 5:
			    	//32-bit
			    	fieldVal = parse32Bit(protoHeader.fieldType, bytes, currentIndex);
			    	break;
			    default:
			    	break;
		    }

		    currentIndex += lastReadLength;
		    return fieldVal;
		}

        /**
        * Parses a Varint value from the buffer
        */
		private function parseVarint(type, buf, idx) {
			switch(type) {
				case "sint32":
					return parseSignedVarInt(buf, idx);
				case "int32":
				case "uint32":
				case "enum":
					return parseUnsignedVarInt(buf, idx);
				case "int64":
				case "uint64":
					return parseUnsignedVarLong(buf, idx);
				case "sint64":
					return parseSignedVarLong(buf, idx);
				case "bool":
					return parseUnsignedVarInt(buf, idx) == 1;
				default:
					System.println("Unknown Varint type: " + type);
					break;
			}

			return null;
		}

        /**
        * Parses a length delimited value from the buffer
        */
		private function parseLengthDelimited(type, buf, idx) {
			switch(type) {
				case "string":
					return parseString(buf, idx);
				case "bytes":
				case "embedded":
					return parseLengthDelimitedVal(buf, idx);
				case "repeated":
					return parseRepeatedElements(buf, idx);
				default:
					System.println("Unknown Length Delimited type: " + type);
					break;
			}

			return null;
		}

        /**
        * Parses a 32 bit value from a buffer at a given index
        */
		private function parse32Bit(type, buf, idx) {
			lastReadLength += 4;
			switch(type) {
				case "float":
					return parseFloat(buf, idx);
				case "fixed32":
					return ProtoUtils.readUintLE(buf, idx);
				case "sfixed32":
					return ProtoUtils.readSintLE(buf, idx);
				default:
					System.println("Unknown 32 bit type: " + type);
					break;
			}

			return null;
		}

        /**
        * Parses a 64 bit value from a buffer
        */
		private function parse64Bit(type, buf) {
			lastReadLength += 8;
			switch(type) {
				case "double":
					return parse64bitFloat(0, 4, buf, 0);
				case "fixed64":
				case "sfixed64":
					return parseUnsignedLongLE(buf);
				default:
					System.println("Unknown 64 bit type: " + type);
					break;
			}

			return null;
		}

        /**
        * Parses an unsigned Varint value from a buffer at a given index
        */
		private function parseUnsignedVarInt(buf, idx) {
			var shifter = 0;
			var val = 0;

		    do
		    {
		        idx++;
		        val |= (buf[idx] & 0x7F) << shifter;
		        shifter += 7;
		        lastReadLength++;
		    }
		    while (buf[idx] & 0x80);

		    return val;
		}

        /**
        * Parses an unsigned var long value from the buffer at the provided index
        */
		private function parseUnsignedVarLong(buf, idx) {
			var shifter = 0;
			var val = 0l;

		    do
		    {
		        idx++;
		        val |= (buf[idx] & 0x7F) << shifter;
		        shifter += 7;
		        lastReadLength++;
		    }
		    while (buf[idx].toLong() & 0x80l);

		    return val;
		}

        /**
        * Parses an signed Varint value from the buffer at the provided index
        */
		private function parseSignedVarInt(buf, idx) {
	        var raw = parseUnsignedVarInt(buf, idx);
	        var temp = (((raw << 31) >> 31) ^ raw) >> 1;
	        // This extra step lets us deal with the largest signed values by treating
	        // negative results from read unsigned methods as like unsigned values.
	        // Must re-flip the top bit if the original read value had it set.
	        return temp ^ (raw & (1 << 31));

		}

        /**
        * Parses a signed var long value from the buffer at the provided index
        */
		private function parseSignedVarLong(buf, idx) {
	        var raw = parseUnsignedVarLong(buf, idx);
	        var temp = (((raw << 63) >> 63) ^ raw) >> 1;
	        // This extra step lets us deal with the largest signed values by treating
	        // negative results from read unsigned methods as like unsigned values.
	        // Must re-flip the top bit if the original read value had it set.
	        return temp ^ (raw & (1l << 63));

		}

        /**
        * Parses a little endian unsigned long value from the buffer at the provided index
        */
		private function parseUnsignedLongLE(buf) {
			if(buf.size() != 8) {
				System.println("Buffer size must be of length 8 or 64 bits to parse!");
				return 0l;
			}

			var higher = ProtoUtils.readUintLE(buf, 4);
			var lower = ProtoUtils.readUintLE(buf, 0);
			var combined = ((higher << 32) | lower);
			return combined;
		}

        /**
        * Parses a 32 bit float value from the buffer at the provided index
        */
		private function parseFloat(buf, idx) {
			idx++;
			var val = []b;

			for(var i = 0; i < 4; i++) {
				val.add(buf[idx + i]);
			}

			return val.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {:endianness => Lang.ENDIAN_LITTLE});
		}

        /**
        * Parses a String from the buffer at the provided index
        */
		private function parseString(buf, idx) {
			var val = parseLengthDelimitedVal(buf, idx);
			return StringUtil.convertEncodedString(val, {:fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
								:toRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT});
		}

        /**
        * Parses an length delimited value from the buffer at the provided index
        */
		private function parseLengthDelimitedVal(buf, idx) {
			var length = parseUnsignedVarInt(buf, idx);
			idx += lastReadLength + 1;

			var val = []b;

			for(var i = 0; i < length; i++) {
				val.add(buf[idx + i]);
			}

			lastReadLength += length;

			return val;
		}

        /**
        * Parses a 64 bit float (double) value from the buffer at the provided index
        */
		private function parse64bitFloat(off0, off1, buf, pos) {
            var lo = ProtoUtils.readUintLE(buf, pos + off0).toLong(),
                hi = ProtoUtils.readUintLE(buf, pos + off1).toLong();

            var sign = (hi >> 31) * 2 + 1;
            var exponent = hi >> 20 & 2047;
            var mantissa = 4294967296l * (hi & 1048575l) + lo;

            if(exponent == 2047) {
              if(mantissa == 0) {
                return NaN;
              } else {
                return sign * INFINITY;
              }
            } else {
              if(exponent == 0) {
                  return sign * 5e-324 * mantissa;
                } else {
                  return sign * Math.pow(2, exponent - 1075) * (mantissa + 4503599627370496l);
                }
            }

        }

        /**
        * Parses a primitive array value from the buffer at the provided index
        */
        private function parseRepeatedElements(buf, idx) {
        	var values = parseLengthDelimitedVal(buf, idx);
        	var arr = [];
		    var protoHeader = ProtoUtils.parseProtoHeader(buf[currentIndex], memberDict);

		    if(protoHeader != null) {
			    var fieldTypeArr = memberDict[protoHeader.fieldNum];

			    if(fieldTypeArr.size() != 2) {
				    System.println("Unable to parse repeated field type!");
				    return arr;
			    }

			    var repeatedType = fieldTypeArr[1];
			    protoHeader.fieldType = repeatedType;
			    protoHeader.wireType = ProtoUtils.getWireTypeForFieldType(repeatedType);

			    if(protoHeader.wireType < 0) {
			    	System.println("Found unknown wire type for repeated type: " + repeatedType);
			    	return arr;
			    }

	        	currentIndex++;

	        	for(var i = 0; i < values.size(); i += lastReadLength) {

	        		var fieldVal = getDecodedValue(protoHeader, buf);

			    	if(fieldVal != null) {
			    		arr.add(fieldVal);
			    	} else {
				    	System.println("Val was null! Unable to add value to array for field number: " + protoHeader.fieldNum);
				    }
	        	}
        	} else {
        		System.println("An error occurred when attempting to parse the protobuf header!");
        	}

        	lastReadLength = 0; //reset this since we've already updated the array position
        	return arr;
        }
	}
}