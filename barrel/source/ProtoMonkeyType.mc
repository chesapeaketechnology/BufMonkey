using Toybox.StringUtil;
using Toybox.Lang;
using Toybox.System;

module ProtoMonkey {

	class ProtoMonkeyType {
	
		protected var memberDict = {};
	
		const MSB = 128;
		const MAX_BYTE_VALUE = 255;
		const LAST_THREE = 7;
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
		    	//System.println("i: " + i);
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
				case "int64":
				case "uint64":
					return parseUnsignedVarInt(buf, idx);
				case "bool":
					return parseUnsignedVarInt(buf, idx) == 1;
				case "enum":
					//unhandled
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
		
		function parseSignedVarInt(buf, idx) {
	        var raw = parseUnsignedVarInt(buf, idx);
	        var temp = (((raw << 31) >> 31) ^ raw) >> 1;
	        // This extra step lets us deal with the largest signed values by treating
	        // negative results from read unsigned methods as like unsigned values.
	        // Must re-flip the top bit if the original read value had it set.
	        return temp ^ (raw & (1 << 31));
	                         
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
	}
	
}