using Toybox.StringUtil;
using Toybox.Lang;
using Toybox.System;

(:test)
module BufMonkey {
	const PROTOBUF_TEST = "089ADF918904109CDEF6D3011DECD10542220F74706F6F7030303334392828282821";
	
	(:test)
	function testVarint(logger) {
	    var bytes = StringUtil.convertEncodedString(PROTOBUF_TEST, 	{:fromRepresentation => StringUtil.REPRESENTATION_STRING_HEX, :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY});

		var test1 = new Test1();
		test1.decode(bytes);
		
		System.println(test1);
	    
	    return true; // returning true indicates pass, false indicates failure
	}
}
