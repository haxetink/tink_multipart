package ;

import tink.io.Source;
import tink.http.Header;
import tink.multipart.parsers.BusboyParser;

using tink.CoreApi;

class RunTests {

	static function main() {
		var parser = new BusboyParser(new Header([
			new HeaderField('Content-Type', 'multipart/form-data; boundary=----------287032381131322'),
			new HeaderField('Content-Length', 514),
		]));
		var body = '------------287032381131322
Content-Disposition: form-data; name="datafile1"; filename="r.gif"
Content-Type: image/gif

GIF87a.............,...........D..;
------------287032381131322
Content-Disposition: form-data; name="datafile2"; filename="g.gif"
Content-Type: image/gif

GIF87a.............,...........D..;
------------287032381131322
Content-Disposition: form-data; name="datafile3"; filename="b.gif"
Content-Type: image/gif

GIF87a.............,...........D..;
------------287032381131322--
';
		
		var result = [];
		parser.parse(body).forEach(function(o) {
			switch o.body {
				case Field(v): result.push(o.name + ':$v');
				case File(f): result.push(o.name + ':${f.filename}-${f.mimeType}');
			}
			return true;
		}).handle(function(ended) {
			travix.Logger.exit(ended.isSuccess() && result.join(',') == 'datafile1:r.gif-image/gif,datafile2:g.gif-image/gif,datafile3:b.gif-image/gif' ? 0 : 1);
		});
	}

}