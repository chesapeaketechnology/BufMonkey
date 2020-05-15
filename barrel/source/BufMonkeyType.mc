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
		hidden var iter = 0;
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
			var i = 0;
		    while(i < bytes.size()) {
		    	lastReadLength = 0;
		    	System.println("i: " + i);
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

			    var fieldType = memberDict[fieldNum];

			    var fieldVal = null;

			    switch(wireType) {
			    	case 0:
				    	//varint
				    	fieldVal = parseVarint(fieldType, bytes, i);
				    	System.println("Varint: " + fieldVal);
				    	i += lastReadLength + 1;
				    	break;
				    case 1:
				    	//TODO:
				    	System.println("bytes: " + bytes.slice(i, i + 9));
				    	fieldVal = parse64Bit(fieldType, bytes.slice(i + 1, i + 9));
				    	System.println("64 bit: " + fieldVal);
				    	i += 9;
				    	break;
				    case 2:
				    	//length-delimited
				    	fieldVal = parseLengthDelimited(fieldType, bytes, i);
				    	System.println("Length Delimited: " + fieldVal);
				    	i += lastReadLength + 1;
				    	break;
				    case 5:
				    	//32-bit
				    	fieldVal = parse32Bit(fieldType, bytes, i);
				    	System.println("Float: " + fieldVal);
				    	i += 5;
				    	break;
				    default:
				    	break;
			    }

			    if(fieldVal != null) {
			    	setValue(fieldNum, fieldVal);
			    } else {
			    	System.println("Val was null! Unable to set field: " + fieldNum);
			    }

			    System.println("iter: " + iter);
		    }
		}

		function parseVarint(type, buf, idx) {
			switch(type) {
				case "sint32":
					return parseSignedVarInt(buf, idx);
				case "int32":
				case "uint32":
					return parseUnsignedVarInt(buf, idx);
				case "int64":
				case "uint64":
					return parseUnsignedVarLong(buf, idx);
				case "sint64":
					return parseSignedVarLong(buf, idx);
				case "bool":
					return parseUnsignedVarInt(buf, idx) == 1;
				case "enum":
					//unhandled
					//TODO:
				default:
					break;
			}

			return null;
		}

		function parseLengthDelimited(type, buf, idx) {
			switch(type) {
				case "string":
					return parseString(buf, idx);
				case "bytes":
					return parseLengthDelimitedVal(buf, idx);
				case "embedded messages":
					//TODO
				case "packed repeated fields":
					//TODO
				default:
					break;
			}

			return null;
		}

		function parse32Bit(type, buf, idx) {
			switch(type) {
				case "float":
					return parseFloat(buf, idx);
				case "fixed32":
					//TODO
				case "sfixed32":
					//TODO
				default:
					break;
			}

			return null;
		}

		function parse64Bit(type, buf) {
			switch(type) {
				case "double":
				case "fixed64":
					var double = parse64bitFloat(0, 4, buf, 0).toDouble();
					System.println("double: " + double);
					return double;
				case "sfixed64":
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

		    iter = idx;
		    return val;
		}

		function parseUnsignedVarLong(buf, idx) {
			var shifter = 0;
			var val = 0l;

		    do
		    {
		    	var longVal = buf[idx].toLong();
		    	lastReadLength++;
		        idx++;
		        val |= (longVal & 0x7F) << shifter;
		        shifter += 7;
		    }
		    while (buf[idx].toLong() & 0x80l);

		    iter = idx;
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
			var length = parseUnsignedVarInt(buf, idx);
			idx += lastReadLength;
			var val = []b;

			for(var i = 0; i <= length; i++) {
				val.add(buf[idx + i]);
				lastReadLength++;
			}

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

        function readUintLE(buf, pos) {
        	return buf.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {:offset => pos, :endianness => Lang.ENDIAN_LITTLE});
		}

		function readUintBE(buf, pos) {
		    return buf.decodeNumber(Lang.NUMBER_FORMAT_UINT32, {:offset => pos, :endianness => Lang.ENDIAN_BIG});
		}

	}
	
}