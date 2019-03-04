package;

import tink.multipart.Parser;
import tink.multipart.Parsed;
import tink.multipart.parsers.*;
import tink.http.Header;
import tink.http.StructuredBody;
import tink.unit.*;
import tink.streams.Stream;

using tink.io.Source;
using tink.CoreApi;

@:asserts
@:allow(tink.unit)
class ParserTest {
	
	var body:String;
	
	public function new() {
		body = '------------287032381131322\r\nContent-Disposition: form-data; name="datafile1"; filename="r.gif"\r\nContent-Type: image/gif\r\n\r\nGIF87a.............,...........D..;\r\n------------287032381131322\r\nContent-Disposition: form-data; name="datafile2"; filename="g.gif"\r\nContent-Type: image/gif\r\n\r\nGIF87a.............,...........D..;\r\n------------287032381131322\r\nContent-Disposition: form-data; name="datafile3"; filename="b.gif"\r\nContent-Type: image/gif\r\n\r\nGIF87a.............,...........D..;\r\n------------287032381131322--';
	}
	
	@:describe('Test Busboy parser')
	@:variant(target.body)
	@:variant(target.body + '\r\n')
	@:variant(target.body + '\r\nrubbish')
	public function busboy(body:String) {
		var parser = new BusboyParser('multipart/form-data; boundary=----------287032381131322');
		return parseWith(parser, asserts);
	}
	
	
	@:describe('Test Tink parser')
	@:variant(target.body)
	@:variant(target.body + '\r\n')
	@:variant(target.body + '\r\nrubbish')
	public function tinkParser(body:String) {
		var parser = new TinkParser('----------287032381131322');
		return parseWith(parser, asserts);
	}
	
	function parseWith(parser:Parser, asserts:AssertionBuffer) {
		var result = [];
		return parser.parse(body).forEach(function(o:Parsed) {
			switch o.value {
				case Value(v): result.push(o.name + ':$v');
				case File(f): result.push(o.name + ':${f.fileName}-${f.mimeType}');
			}
			return Resume;
		}).map(function(o) {
			asserts.assert(o == Depleted);
			asserts.assert(result.join(',') == 'datafile1:r.gif-image/gif,datafile2:g.gif-image/gif,datafile3:b.gif-image/gif');
			return asserts.done();
		});
	}
}