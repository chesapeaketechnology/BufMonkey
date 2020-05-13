using Toybox.StringUtil;
using Toybox.Lang;
using Toybox.System;

(:test)
module ProtoMonkey {
	const PROTOBUF_TEST = "089ADF918904109CDEF6D3011DECD10542220F74706F6F7030303334392828282821";
	const MSB = 128;
	const MAX_BYTE_VALUE = 255;
	const LAST_THREE = 7;
	var iter = 0;
	var lastReadLength = 0;
	
	(:test)
	function testVarint(logger) {
	    var bytes = StringUtil.convertEncodedString(PROTOBUF_TEST, 	{:fromRepresentation => StringUtil.REPRESENTATION_STRING_HEX, :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY});

		var test1 = new Test1();
		test1.decode(bytes);
		
		System.println(test1);
	    
	    return true; // returning true indicates pass, false indicates failure
	}
	
	function parseUnsignedVarInt(logger, buf, idx) {
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
	
	function parseSignedVarInt(logger, buf, idx) {
        var raw = parseUnsignedVarInt(logger, buf, idx);
        var temp = (((raw << 31) >> 31) ^ raw) >> 1;
        // This extra step lets us deal with the largest signed values by treating
        // negative results from read unsigned methods as like unsigned values.
        // Must re-flip the top bit if the original read value had it set.
        return temp ^ (raw & (1 << 31));
                         
	}
	
	function parseFloat(logger, buf, idx) {
		idx++;
		var val = []b;
		for(var i = 0; i < 4; i++) {
			//logger.debug("idx + i: " + (idx + i));
			val.add(buf[idx + i]);
		}
		//logger.debug("val: " + val);
		return val.decodeNumber(Lang.NUMBER_FORMAT_FLOAT, {:endianness => Lang.ENDIAN_LITTLE});
	}
	
	function parseString(logger, buf, idx) {
		var length = parseUnsignedVarInt(logger, buf, idx);
		idx += lastReadLength;
		var val = []b;
		for(var i = 0; i <= length; i++) {
			val.add(buf[idx + i]);
			lastReadLength++;
		}
		return StringUtil.convertEncodedString(val, {:fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY, 
							:toRepresentation => StringUtil.CHAR_ENCODING_UTF8});
	}
}
