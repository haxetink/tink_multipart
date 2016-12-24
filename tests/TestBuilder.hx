package;

import tink.io.Source;
import tink.http.Header;
import tink.multipart.Multipart;
import tink.unit.Assert.*;

using tink.CoreApi;

class TestBuilder {
	public function new() {}
	
	@:describe('Construct a value-only multipart body')
	public function testValue() {
		var m = new Multipart();
		var result = '';
		for(i in 0...1) {
			m.addValue('name$i', 'value$i');
			result += '--${m.boundary}\r\nContent-Disposition: form-data; name="name$i"\r\n\r\nvalue$i\r\n';
		}
		result += '--${m.boundary}--';
		return m.toIdealSource().all().map(function(bytes) return equals(result, bytes.toString()));
	}
	
	@:describe('Convert boundary to a content-type header value')
	public function testHeaderValue() {
		var m = new Multipart();
		var field = new HeaderField('content-type', m.boundary);
		return equals('multipart/form-data; boundary=${m.boundary}', field.value);
	}
}