package tink.multipart;

import tink.http.Header;
import tink.http.Request;

using tink.CoreApi;
using tink.io.Source;

@:forward
abstract Multipart(Pair<String, Array<Part>>) from Pair<String, Array<Part>> {
	static var ALPHABETS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
	
	public var boundary(get, never):String;
	inline function get_boundary() return this.a;
		
	static function makeBoundary() {
		var buf = new StringBuf();
		buf.add('--------------------');
		for(i in 0...20) buf.addChar(ALPHABETS.charCodeAt(Std.random(ALPHABETS.length)));
		return buf.toString();
	}
	
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
	
	public inline function iterator() {
		return this.b.iterator();
	}
		
	public inline function concat(parts) {
		return new Multipart(this.a, this.b.concat(parts));
	}
	
	public inline function getContentTypeHeader(subtype = 'mixed') {
		return new HeaderField(CONTENT_TYPE, 'multipart/$subtype; boundary=${this.a}');
	}
	
	@:to
	public function toIdealSource():IdealSource {
		var body = Source.EMPTY;
		var boundary = this.a;
		for(part in this.b) {
			body = body
				.append('--$boundary\r\n')
				.append(part.header.toString())
				.append(part.body)
				.append('\r\n');
		}
		return body.append('--$boundary--');
	}
}