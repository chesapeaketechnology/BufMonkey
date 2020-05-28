module BufMonkey {
	/**
    * Simple POJO class for a Protobuf message header
    */
	class ProtoHeader {
		/*
	    * Protobuf message type (ie. Varint, 64-bit, Length Delimited, 32-bit)
	    */
		public var wireType;

		/**
	    * Number value associated with the field (ie. int32 myField = 1)
	    */
		public var fieldNum;

		/**
	    * Type value associated with the field (ie. int32)
	    */
		public var fieldType;

		function initialize(wireType, fieldNum, fieldType) {
			self.wireType = wireType;
			self.fieldNum = fieldNum;
			self.fieldType = fieldType;
		}
	}
}