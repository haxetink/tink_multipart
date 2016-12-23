package tink.multipart;

import tink.http.Header;
import tink.http.Request;
import tink.io.Source;
using tink.CoreApi;

class Multipart {
	public static function check(r:IncomingRequest):Option<Pair<ContentType, Source>> {
		return switch [r.body, r.header.contentType()] {
			case [Plain(src), Success(contentType)] if(contentType.type == 'multipart'):
				Some(new Pair(contentType, src));
			default:
				None;
		}
	}
}