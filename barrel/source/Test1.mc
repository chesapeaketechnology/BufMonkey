using Toybox.System;

module ProtoMonkey {

	class Test1 extends ProtoMonkeyType {
		
		//int
		public var a;
		
		//int
		public var b;
		
		//float
		public var c;
		
		//string
		public var d;
		
		
		function initialize() {
			ProtoMonkeyType.initialize({
			    1 => "sint32",
			    2 => "sint32",
			    3 => "float",
			    4 => "string"
			});
		}
		
		function toString() {
			System.println("Test1 {");
			System.println("	a: " + a);
			System.println("	b: " + b);
			System.println("	c: " + c);
			System.println("	d: " + d);
			System.println("}");
		}
		
		function setValue(position, value) {
			switch(position) {
				case 1:
					a = value;
					break;
				case 2:
					b = value;
					break;
				case 3:
					c = value;
					break;
				case 4:
					d = value;
					break;
				default:
					System.println("Unknown value.");
					break;
			}
		}
	}
}