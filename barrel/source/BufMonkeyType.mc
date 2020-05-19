using Toybox.StringUtil;
using Toybox.Lang;
using Toybox.System;

module BufMonkey {

	class BufMonkeyType {

		protected var memberDict = {};

		const MSB = 128;
		const MAX_BYTE_VALUE = 255;
		const LAST_THREE = 7;
		const Infinity = 0x7FF0000000000000;
		hidden var i = 0;
		hidden var lastReadLength = 0;


		function initialize(dict) {
			memberDict = dict;
		}

		function setValue(position, value) {
			//to be overriden by subclass
		}

		function encode() {

		}

		function decode(bytes) {
			System.println("---------------- START DECODE -----------------");
			System.println("bytes size: " + bytes.size());
		    while(i < bytes.size()) {
			     //strip MSB
			    var currentBytes = bytes[i];
			    if(bytes[i] > MSB - 1) {

			    	var strippedFirst = bytes[i]^MSB;
			    	System.println("bytes 0: " + strippedFirst);
			    	currentBytes = strippedFirst;
			    }

			    //get wire type
			    var wireType = currentBytes & LAST_THREE;
			    System.println("Wire Type: " + wireType);

			    //get field number
			    var fieldNum = currentBytes >> 3;
			    System.println("Field Number: " + fieldNum);

			    var fieldTypeArr = memberDict[fieldNum];

		    	var fieldType = fieldTypeArr[0];

		    	var fieldVal = getDecodedValue(wireType, fieldNum, fieldType, bytes);

			    if(fieldVal != null) {
			    	setValue(fieldNum, fieldVal);
			    } else {
			    	System.println("Val was null! Unable to set field: " + fieldNum);
			    }

			    i++;
		    }
		}

		function getDecodedValue(wireType, fieldNum, fieldType, bytes) {
			lastReadLength = 0;
	    	System.println("i: " + i);
	    	System.println("bytes left: " + bytes.slice(i, bytes.size()));

		    var fieldVal = null;

		    switch(wireType) {
		    	case 0:
			    	//varint
			    	fieldVal = parseVarint(fieldType, bytes, i);
			    	System.println("Varint: " + fieldVal);
			    	break;
			    case 1:
			    	//TODO:
			    	System.println("bytes 64: " + bytes.slice(i + 1, i + 9));
			    	fieldVal = parse64Bit(fieldType, bytes.slice(i + 1, i + 9));
			    	System.println("64 bit: " + fieldVal);
			    	break;
			    case 2:
			    	//length-delimited
			    	fieldVal = parseLengthDelimited(fieldType, bytes, i);
			    	System.println("Length Delimited: " + fieldVal);
			    	break;
			    case 5:
			    	//32-bit
			    	fieldVal = parse32Bit(fieldType, bytes, i);
			    	System.println("Float: " + fieldVal);
			    	break;
			    default:
			    	break;
		    }
		    System.println("lastReadLength: " + lastReadLength);
		    i += lastReadLength;
		    System.println("i: " + i);
		    return fieldVal;
		}

		function parseVarint(type, buf, idx) {
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
					//unhandled
					//TODO:
				default:
					break;
			}

			return null;
		}

		function parseLengthDelimited(type, buf, idx) {
			System.println("Starting parseLengthDelimited");
			switch(type) {
				case "string":
					return parseString(buf, idx);
				case "bytes":
				case "embedded":
					return parseLengthDelimitedVal(buf, idx);
				case "repeated":
					return parseRepeatedElements(buf, idx);
					//TODO
				default:
					//embedded field

					break;
			}

			return null;
		}

		function parse32Bit(type, buf, idx) {
			lastReadLength += 4;
			switch(type) {
				case "float":
					return parseFloat(buf, idx);
				case "fixed32":
					return readUintLE(buf, idx);
				case "sfixed32":
					return readSintLE(buf, idx);
					//TODO
				default:
					break;
			}

			return null;
		}

		function parse64Bit(type, buf) {
			lastReadLength += 8;
			switch(type) {
				case "double":
					var double = parse64bitFloat(0, 4, buf, 0).toDouble();
					System.println("double: " + double);
					return double;
				case "fixed64":
				case "sfixed64":
					return parseUnsignedLongLE(buf);
					//TODO
				default:
					break;
			}

			return null;
		}

		function parseUnsignedVarInt(buf, idx) {
			var shifter = 0;
			var val = 0;

		    do
		    {
		    	lastReadLength++;
		        idx++;
		        val |= (buf[idx] & 0x7F) << shifter;
		        shifter += 7;
		    }
		    while (buf[idx] & 0x80);

		    return val;
		}

		function parseUnsignedVarLong(buf, idx) {
			var shifter = 0;
			var val = 0l;

		    do
		    {
		    	lastReadLength++;
		        idx++;
		        val |= (buf[idx] & 0x7F) << shifter;
		        shifter += 7;
		    }
		    while (buf[idx].toLong() & 0x80l);

		    return val;
		}

		function parseSignedVarInt(buf, idx) {
	        var raw = parseUnsignedVarInt(buf, idx);
	        var temp = (((raw << 31) >> 31) ^ raw) >> 1;
	        // This extra step lets us deal with the largest signed values by treating
	        // negative results from read unsigned methods as like unsigned values.
	        // Must re-flip the top bit if the original read value had it set.
	        return temp ^ (raw & (1 << 31));

		}

		function parseSignedVarLong(buf, idx) {
	        var raw = parseUnsignedVarLong(buf, idx);
	        var temp = (((raw << 63) >> 63) ^ raw) >> 1;
	        // This extra step lets us deal with the largest signed values by treating
	        // negative results from read unsigned methods as like unsigned values.
	        // Must re-flip the top bit if the original read value had it set.
	        return temp ^ (raw & (1l << 63));

		}

		function parseUnsignedLongLE(buf) {
			if(buf.size() != 8) {
				System.println("Buffer size must be of length 8 or 64 bits to parse!");
				return 0l;
			}

			var higher = readUintLE(buf, 4);
			var lower = readUintLE(buf, 0);
			var combined = ((higher << 32) | lower);
			return combined;
		}

		function parseFloat(buf, idx) {
			idx++;
			var val = []b;

			for(var i = 0; i < 4; i++) {
				val.add(buf[idx + i]);
			}

			return val.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {:endianness => Lang.ENDIAN_LITTLE});
		}

		function parseString(buf, idx) {
			var val = parseLengthDelimitedVal(buf, idx);
			return StringUtil.convertEncodedString(val, {:fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
								:toRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT});
		}

		function parseLengthDelimitedVal(buf, idx) {
			System.println("ldv buf: " + buf);
			var length = parseUnsignedVarInt(buf, idx);
			System.println("ldv length: " + length);
			idx += lastReadLength + 1;

			var val = []b;

			for(var i = 0; i < length; i++) {
				val.add(buf[idx + i]);
			}

			lastReadLength += length;

			return val;
		}

		function parse64bitFloat(off0, off1, buf, pos) {
            var lo = readUintLE(buf, pos + off0).toLong(),
                hi = readUintLE(buf, pos + off1).toLong();

            var sign = (hi >> 31) * 2 + 1;
            var exponent = hi >> 20 & 2047;
            var mantissa = 4294967296l * (hi & 1048575l) + lo;

            if(exponent == 2047) {
              if(mantissa == 0) {
                return NaN;
              } else {
                return sign * Infinity;
              }
            } else {
              if(exponent == 0) {
                  return sign * 5e-324 * mantissa;
                } else {
                  return sign * Math.pow(2, exponent - 1075) * (mantissa + 4503599627370496l);
                }
            }

        }

        function parseRepeatedElements(buf, idx) {
        	System.println("Starting parseRepeatedElements");
        	var values = parseLengthDelimitedVal(buf, idx);
        	System.println("R values: " + values);
        	var j = 0;
        	System.println(idx);
        	System.println(lastReadLength);

        	var arr = [];
        	var fieldVal = 0;

    	    //strip MSB
		    var currentBytes = buf[idx];
		    if(buf[idx] > MSB - 1) {

		    	var strippedFirst = buf[idx]^MSB;
		    	System.println("bytes 0: " + strippedFirst);
		    	currentBytes = strippedFirst;
		    }

		    //get field number
		    var fieldNum = currentBytes >> 3;
		    System.println("R Field Number: " + fieldNum);

		    var fieldTypeArr = memberDict[fieldNum];

		    if(fieldTypeArr.size() != 2) {
			    System.println("Unable to parse repeated field type!");
			    return arr;
		    }

		    var repeatedType = fieldTypeArr[1];
		    var wireType = getWireTypeForFieldType(repeatedType);

		    if(wireType < 0) {
		    	System.println("Found unknown wire type for repeated type: " + repeatedType);
		    	return arr;
		    }

        	i++;
        	System.println("values.size() = " + values.size());
        	while(j < values.size()) {
        		System.println("j = " + j);
        		fieldVal = getDecodedValue(wireType, fieldNum, repeatedType, buf);

		    	if(fieldVal != null) {
		    		arr.add(fieldVal);
		    		System.println("R array values : " + arr);
		    	}

		    	j += lastReadLength;
        	}

        	lastReadLength = 0; //reset this since we've already updated the array position
        	return arr;
        }

        function readUintLE(buf, pos) {
        	return buf.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {:offset => pos, :endianness => Lang.ENDIAN_LITTLE});
		}

		function readUintBE(buf, pos) {
		    return buf.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {:offset => pos, :endianness => Lang.ENDIAN_BIG});
		}

		function readSintLE(buf, pos) {
        	return buf.decodeNumber(Lang.NUMBER_FORMAT_SINT32, {:offset => pos, :endianness => Lang.ENDIAN_LITTLE});
		}

		function readSintBE(buf, pos) {
		    return buf.decodeNumber(Lang.NUMBER_FORMAT_SINT32, {:offset => pos, :endianness => Lang.ENDIAN_BIG});
		}

		function get_byte_as_bits(val) {
	      var bits = "";
		  for (var i = 7; 0 <= i; i--) {
		  	var bit = (val & (1 << i)) ? '1' : '0';
		    bits += bit;
		  }

		  return bits;
		}

		function getWireTypeForFieldType(fieldType) {
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