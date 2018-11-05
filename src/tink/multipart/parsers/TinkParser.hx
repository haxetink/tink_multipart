package tink.multipart.parsers;

import haxe.io.Bytes;
import tink.multipart.Parser;
import tink.multipart.Parsed;
import tink.streams.RealStream;
import tink.streams.Stream;
import tink.http.Header;
import tink.http.StructuredBody;
import tink.io.StreamParser;

using tink.io.Source;
using tink.CoreApi;

class TinkParser implements Parser {
	
	var boundary:String;
	
	public function new(boundary) {
		this.boundary = boundary;
	}
	
	public function parse(src:IdealSource):RealStream<Parsed> {
		
		var split = src.split('--$boundary');
		
		var result = split.delimiter.next(function(_) {
			var s = split.after;
			var delim:tink.Chunk = '\r\n--$boundary';
			
			var stream:RealStream<Parsed> = Generator.stream(function next(step:Step<Parsed, Error>->Void) {
				getChunk(s, delim).handle(function (o) switch o {
					case Success(None): 
						step(End);
					case Success(Some( { chunk: chunk, rest: rest } )): 
						s = rest;
						switch chunk.a.byName('content-disposition') {
							case Success(v):
								chunk.b.all().handle(function(bytes) {
									var ext = v.getExtension();
									step(Link(new Named(
										ext['name'],
										switch ext['filename'] {
											case null: Value(bytes.toString());
											case filename: File(UploadedFile.ofBlob(filename, chunk.a.byName('content-type').orNull(), bytes));
										}
									), Generator.stream(next)));
								});
							case Failure(e):
								step(Fail(e));
						}
					case Failure(e):
						step(Fail(e));
				});
			});
			return stream;
		});
		
		// var result:Promise<RealStream<Chunk>> = s.parse(new Splitter('--$boundary')).next(function(p) {
		// 	var s = p.b; //TODO: make sure it's on its newline
		// 	var stream:RealStream<Chunk> = Generator.stream(function next(step:Step<Chunk, Error>->Void) {
		// 		getChunk(s, delim).handle(function (o) switch o {
		// 			case Success(None): 
		// 				step(End);
		// 			case Success(Some( { chunk: chunk, rest: rest } )): 
		// 				s = rest; 
		// 				switch chunk.a.byName('content-disposition') {
		// 					case Success(v):
		// 						chunk.b.all().handle(function(bytes) {
		// 							var ext = v.getExtension();
		// 							step(Link(new Named(
		// 								ext['name'],
		// 								switch ext['filename'] {
		// 									case null: Value(bytes.toString());
		// 									case filename: File(UploadedFile.ofBlob(filename, chunk.a.byName('content-type').orNull(), bytes));
		// 								}
		// 							), Generator.stream(next)));
		// 						});
		// 					case Failure(e):
		// 						step(Fail(e));
		// 				}
		// 			case Failure(e):
		// 				step(Fail(e));
		// 		});
		// 	});
		// 	return stream;
		// });
		
		return (Stream.promise(cast result):Stream<Parsed, Error>);
	}
	 
	function getChunk(s:IdealSource, delim:tink.Chunk):Surprise<Option<{ chunk:Pair<Header, IdealSource>, rest:IdealSource }>, Error> {
		var split = s.split(delim);
		return split.before.parse(new HeaderParser(function (line, fields) {
			return
				Success(
					if (line == '--') null
					else {
						fields.push(HeaderField.ofString(line));
						new Header(fields);
					}
				);
		})).next(function (o) return 
			if (o.a == null) None
			else Some({ 
				chunk: o,
				rest: split.after,
			})
		);
	}
}