package;

import tink.io.Source;
import tink.http.Header;
import tink.multipart.Parser;
import tink.multipart.parsers.*;

using tink.CoreApi;

class TestParsers {
	
	var body:String;
	
	public function new() {
		body = '------------287032381131322\r\nContent-Disposition: form-data; name="datafile1"; filename="r.gif"\r\nContent-Type: image/gif\r\n\r\nGIF87a.............,...........D..;\r\n------------287032381131322\r\nContent-Disposition: form-data; name="datafile2"; filename="g.gif"\r\nContent-Type: image/gif\r\n\r\nGIF87a.............,...........D..;\r\n------------287032381131322\r\nContent-Disposition: form-data; name="datafile3"; filename="b.gif"\r\nContent-Type: image/gif\r\n\r\nGIF87a.............,...........D..;\r\n------------287032381131322--\r\n';
	}
	
	@:describe('Test Busboy parser')
	public function busboy() {
		var parser = new BusboyParser('multipart/form-data; boundary=----------287032381131322');
		return parseWith(parser);
	}
	
	@:describe('Test Tink parser')
	public function tink() {
		var parser = new TinkParser('----------287032381131322');
		return parseWith(parser);
	}
	
	function parseWith(parser:Parser) {
		var result = [];
		return parser.parse(body).forEach(function(o) {
			switch o.body {
				case Field(v): result.push(o.name + ':$v');
				case File(f): result.push(o.name + ':${f.filename}-${f.mimeType}');
			}
			return true;
		}) >>
			function(ended) {
				if(!ended) return Failure(new Error('Not completed'));
				if(result.join(',') != 'datafile1:r.gif-image/gif,datafile2:g.gif-image/gif,datafile3:b.gif-image/gif') return Failure(new Error('Incorrect result'));
				return Success(Noise);
			}
	}
}