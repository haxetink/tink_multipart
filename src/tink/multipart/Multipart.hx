package tink.multipart;

import tink.http.Header;
import tink.http.Request;

using tink.CoreApi;
using tink.io.Source;

@:forward
abstract Multipart(MultipartBuilder) from MultipartBuilder {
	
	public static function check(r:IncomingRequest):Option<Pair<ContentType, RealSource>> {
		return switch [r.body, r.header.contentType()] {
			case [Plain(src), Success(contentType)] if(contentType.type == 'multipart'):
				Some(new Pair(contentType, src));
			default:
				None;
		}
	}
	
	public inline function new(?boundary)
		this = new MultipartBuilder(boundary);
		
	@:to
	public function toIdealSource():IdealSource
		return this.toIdealSource();
}

abstract Boundary(String) from String to String {
	@:to
	public inline function asHeaderValue():HeaderValue
		return 'multipart/form-data; boundary=$this';
}
	
private class MultipartBuilder {
	static var ALPHABETS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
	
	public var boundary(default, null):Boundary;
	var chunks:Array<Named<ChunkType>>;
	
	public function new(?boundary) {
		this.boundary = switch boundary {
			case null:
				var buf = new StringBuf();
				buf.add('--------------------');
				for(i in 0...20) buf.addChar(ALPHABETS.charCodeAt(Std.random(ALPHABETS.length)));
				buf.toString();
			case v: v;
		}
		chunks = [];
	}
	
	public function addValue(name:String, value:String) {
		chunks.push(new Named(name, Value(value)));
	}
	
	public function addFile(name:String, filename:String, mimeType:String, content:IdealSource) {
		chunks.push(new Named(name, File(filename, mimeType, content)));
	}
	
	public function toIdealSource():IdealSource {
		var body = Source.EMPTY;
		for(chunk in this.chunks) {
			body = body.append('--$boundary\r\n');
			switch chunk.value {
				case Value(v):
					body = body.append('Content-Disposition: form-data; name="${chunk.name}"\r\n\r\n$v');
				case File(filename, mime, content):
					body = body
						.append('Content-Disposition: form-data; name="${chunk.name}"; filename="$filename"\r\nContent-Type: $mime\r\n\r\n')
						.append(content);
			}
			body = body.append('\r\n');
		}
		body = body.append('--$boundary--');
		return body;
	}
}

private enum ChunkType {
	Value(v:String);
	File(filename:String, mimeType:String, content:IdealSource);
}