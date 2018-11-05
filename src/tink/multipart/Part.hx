package tink.multipart;

import tink.http.Header;
import tink.http.Message;
using tink.io.Source;

@:forward
abstract Part(Message<Header, IdealSource>) from Message<Header, IdealSource> to Message<Header, IdealSource> {
	
	public inline function new(header, body)
		this = new Message(header, body);
	
	public static function value(name:String, value:String) {
		return new Part(
			new Header([
				new HeaderField(CONTENT_DISPOSITION, 'form-data; name="$name"')
			]),
			value
		);
	}
	
	public static function file(name:String, filename:String, mimeType:String, content:IdealSource) {
		return new Part(
			new Header([
				new HeaderField(CONTENT_DISPOSITION, 'form-data; name="$name"; filename="$filename"'),
				new HeaderField(CONTENT_TYPE, mimeType),
			]),
			content
		);
	}
}