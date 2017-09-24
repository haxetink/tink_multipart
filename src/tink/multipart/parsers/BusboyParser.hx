package tink.multipart.parsers;

import tink.multipart.Parser;
import tink.multipart.Chunk;
import tink.streams.RealStream;
import tink.streams.Stream;
import tink.http.StructuredBody;
import tink.state.State;

using tink.io.Sink;
using tink.io.Source;
using tink.CoreApi;

@:require(nodejs)
class BusboyParser implements Parser {
	var contentType:String;
	
	public function new(contentType) {
		this.contentType = contentType;
	}
	
	public function parse(source:IdealSource):RealStream<Chunk> {
		var trigger = Signal.trigger();
		var result = new SignalStream(trigger);
		var filesInProgress = new State(0);
		try {
			var busboy = new Busboy({headers: {'content-type': contentType}}); // busboy is only interested in the content-type header
			busboy.on('file', function(fieldname, file, filename, encoding, mimetype) {
				filesInProgress.set(filesInProgress.value + 1);
				Source.ofNodeStream('File part: $filename', file).all() // HACK: needa comsume the file otherwise busboy wont fire the 'finish' event
					.handle(function(o) switch o {
						case Success(bytes):
							trigger.trigger(Data(new Named(fieldname, File(UploadedFile.ofBlob(filename, mimetype, bytes)))));
							filesInProgress.set(filesInProgress.value - 1);
						case Failure(e):
							trigger.trigger(Fail(e));
					});
			});
			busboy.on('field', function(fieldname, val, fieldnameTruncated, valTruncated, encoding, mimetype) {
				trigger.trigger(Data(new Named(fieldname, Value(val))));
			});
			busboy.on('finish', function() {
				filesInProgress.observe().nextTime(function(v) return v == 0)
					.handle(trigger.trigger.bind(End));
			});
			busboy.on('error', function(e:js.Error) trigger.trigger(Fail(Error.withData(e.message, e))));
			
			source.pipeTo(Sink.ofNodeStream('Busboy', busboy)).handle(function(o) switch o {
				case AllWritten: // ok
				case SinkEnded(_): trigger.trigger(Fail(new Error('Sink Ended')));
				case SinkFailed(e, _): trigger.trigger(Fail(e));
			});
		} catch(e:Dynamic) {
			// busboy's constructor may throw js.Error
			trigger.trigger(Fail(new Error(500, e.name + ': ' + e.message)));
		}
		return result;
	}
}

@:jsRequire('busboy')
extern class Busboy extends js.node.stream.Writable<Busboy> {
	function new(options:{headers:Dynamic<String>}); // TODO: more options?
}
