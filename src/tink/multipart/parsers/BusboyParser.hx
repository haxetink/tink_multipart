package tink.multipart.parsers;

import tink.multipart.Parser;
import tink.multipart.Chunk;
import tink.io.IdealSource;
import tink.io.Source;
import tink.io.Sink;
import tink.streams.Stream;
import tink.streams.Accumulator;
import tink.http.Header;

using tink.CoreApi;

@:require(nodejs)
class BusboyParser implements Parser {
	var header:Header;
	
	public function new(header:Header) {
		this.header = header;
	}
	
	public function parse(source:IdealSource):Stream<Chunk> {
		var result = new Accumulator<Chunk>();
		switch header.byName('content-type') {
			case Success(v):
				var busboy = new Busboy({headers: {'content-type': v}}); // busboy is only interested in the content-type header
				busboy.on('file', function(fieldname, file, filename, encoding, mimetype) {
					Source.ofNodeStream('File part: $filename', file).all() // HACK: needa comsume the file otherwise busboy wont fire the 'finish' event
						.handle(function(o) switch o {
							case Success(bytes):
								result.yield(Data({
									name: fieldname,
									body: File({filename: filename, mimeType: mimetype, content: bytes}),
									header: null // TODO: reconstruct it?
								}));
							case Failure(e):
								result.yield(Fail(e));
						});
				});
				busboy.on('field', function(fieldname, val, fieldnameTruncated, valTruncated, encoding, mimetype) {
					result.yield(Data({
						name: fieldname,
						body: Field(val),
						header: null // TODO: reconstruct it?
					}));
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
				
				
			case Failure(_):
				result.yield(Fail(new Error('Content-Type header not present')));
		}
		return result;
	}
}

@:jsRequire('busboy')
extern class Busboy extends js.node.stream.Writable<Busboy> {
	function new(options:{headers:Dynamic<String>});
}