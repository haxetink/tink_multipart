package;

import tink.http.Header;
import tink.multipart.Multipart;
import tink.unit.Assert.*;

using tink.io.Source;
using tink.CoreApi;

class BuilderTest {
	public function new() {}
	
	@:describe('Construct a value-only multipart body')
	@:variant([['name0', 'value0']], 'abc', '--abc\r\nContent-Disposition: form-data; name="name0"\r\n\r\nvalue0\r\n--abc--')
	@:variant([for(i in 0...3) ['name$i', 'value$i']], 'abc', '--abc\r\nContent-Disposition: form-data; name="name0"\r\n\r\nvalue0\r\n--abc\r\nContent-Disposition: form-data; name="name1"\r\n\r\nvalue1\r\n--abc\r\nContent-Disposition: form-data; name="name2"\r\n\r\nvalue2\r\n--abc--')
	public function testValue(values:Array<Array<String>>, boundary:String, output:String) {
		var m = new Multipart(boundary);
		for(p in values) m.addValue(p[0], p[1]);
		return m.toIdealSource().all().map(function(chunk) return assert(chunk == output));
	}
	
	@:describe('Convert boundary to a content-type header value')
	public function testHeaderValue() {
		var m = new Multipart();
		var field = new HeaderField('content-type', m.boundary);
		return assert('multipart/form-data; boundary=${m.boundary}' == field.value);
	}
}