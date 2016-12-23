package tink.multipart.parsers;

import tink.multipart.Parser;
import tink.multipart.Chunk;
import tink.io.IdealSource;
import tink.io.Source;
import tink.io.Sink;
import tink.streams.Stream;
import tink.streams.Accumulator;
import tink.http.StructuredBody;

using tink.CoreApi;

@:require(nodejs)
class BusboyParser implements Parser {
	var contentType:String;
	
	public function new(contentType) {
		this.contentType = contentType;
	}
	
	public function parse(source:IdealSource):Stream<Chunk> {
		var result = new Accumulator<Chunk>();
		try {
			var busboy = new Busboy({headers: {'content-type': contentType}}); // busboy is only interested in the content-type header
			busboy.on('file', function(fieldname, file, filename, encoding, mimetype) {
				Source.ofNodeStream('File part: $filename', file).all() // HACK: needa comsume the file otherwise busboy wont fire the 'finish' event
					.handle(function(o) switch o {
						case Success(bytes):
							result.yield(Data(new Named(fieldname, File(UploadedFile.ofBlob(filename, mimetype, bytes)))));
						case Failure(e):
							result.yield(Fail(e));
					});
			});
			busboy.on('field', function(fieldname, val, fieldnameTruncated, valTruncated, encoding, mimetype) {
				result.yield(Data(new Named(fieldname, Value(val))));
			});
			busboy.on('finish', function() {
				result.yield(End);
			});
			busboy.on('error', function(e) result.yield(Fail(Error.withData('Busboy errored', e))));
			
			source.pipeTo(Sink.ofNodeStream('Busboy', busboy)).handle(function(o) switch o {
				case AllWritten: // ok
				case SinkEnded: result.yield(Fail(new Error('Sink Ended')));
				case SinkFailed(e): result.yield(Fail(e));
			});
		} catch(e:Dynamic) {
			// busboy's constructor may throw js.Error
			result.yield(Fail(new Error(e.message, e.data)));
		}
		return result;
	}
}

@:jsRequire('busboy')
extern class Busboy extends js.node.stream.Writable<Busboy> {
	function new(options:{headers:Dynamic<String>}); // TODO: more options?
}