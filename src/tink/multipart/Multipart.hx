package tink.multipart;

import tink.http.Header;
import tink.http.Request;

using tink.CoreApi;
using tink.io.Source;

@:forward
abstract Multipart(Pair<String, Array<Part>>) from Pair<String, Array<Part>> {
	static var ALPHABETS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
	
	public var boundary(get, never):String;
	public var parts(get, never):Array<Part>;
	
	public static function check(r:IncomingRequest):Option<Pair<ContentType, RealSource>> {
		return switch [r.body, r.header.contentType()] {
			case [Plain(src), Success(contentType)] if(contentType.type == 'multipart'):
				Some(new Pair(contentType, src));
			default:
				None;
		}
	}
	
	public inline function new(?boundary, ?parts) {
		this = new Pair(
			boundary == null ? makeBoundary() : boundary,
			parts == null ? [] : parts
		);
	}
	
	public inline function getContentTypeHeader(subtype = 'mixed') {
		return new HeaderField(CONTENT_TYPE, 'multipart/$subtype; boundary=$boundary');
	}
		
	static function makeBoundary() {
		var buf = new StringBuf();
		buf.add('--------------------');
		for(i in 0...20) buf.addChar(ALPHABETS.charCodeAt(Std.random(ALPHABETS.length)));
		return buf.toString();
	}
	
	public inline function addPart(part:Part) {
		parts.push(part);
	}
	
	public inline function addValue(name:String, value:String) {
		addPart(new Part(
			new Header([
				new HeaderField(CONTENT_DISPOSITION, 'form-data; name="$name"')
			]),
			value
		));
	}
	
	public inline function addFile(name:String, filename:String, mimeType:String, content:IdealSource) {
		addPart(new Part(
			new Header([
				new HeaderField(CONTENT_DISPOSITION, 'form-data; name="$name"; filename="$filename"'),
				new HeaderField(CONTENT_TYPE, mimeType),
			]),
			content
		));
	}
	
	@:to
	public function toIdealSource():IdealSource {
		var body = Source.EMPTY;
		var boundary = this.a;
		for(part in parts) {
			body = body
				.append('--$boundary\r\n')
				.append(part.header.toString())
				.append(part.body)
				.append('\r\n');
		}
		return body.append('--$boundary--');
	}
	
	inline function get_boundary() return this.a;
	inline function get_parts() return this.b;
}