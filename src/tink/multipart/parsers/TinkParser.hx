package tink.multipart.parsers;

import haxe.io.Bytes;
import tink.multipart.Parser;
import tink.multipart.Chunk;
import tink.streams.Stream;
import tink.streams.StreamStep;
import tink.io.IdealSource;
import tink.io.Source;
import tink.http.Header;

using tink.CoreApi;

class TinkParser implements Parser {
	
	var boundary:String;
	
	public function new(boundary) {
		this.boundary = boundary;
	}
	
	public function parse(s:IdealSource):Stream<Chunk> {
		var s = (s:Source).split(Bytes.ofString('--$boundary')).b;//TODO: make sure it's on its newline
		
		var delim = Bytes.ofString('\r\n--$boundary');
		
		return Stream.generate(function ():Future<StreamStep<Chunk>> {
			return getChunk(s, delim).flatMap(function (o) return switch o {
				case Success(None): 
					Future.sync(End);
				case Success(Some( { chunk: chunk, rest: rest } )): 
					s = rest; 
					switch chunk.data.byName('content-disposition') {
						case Success(v):
							var ext = v.getExtension();
							switch [ext['name'], ext['filename']] {
								case [name, null]:
									chunk.rest.all().map(function(o) return switch o {
										case Success(bytes):
											Data({
												name: name,
												body: Field(bytes.toString()),
												header: chunk.data
											});
										case Failure(e):
											Fail(e);
									});
								case [name, filename]:
									Future.sync(Data({
										name: name, 
										body: File({
											filename: filename, 
											mimeType: chunk.data.byName('content-type').orNull(),
											content: chunk.rest,
										}),
										header: chunk.data,
									}));
							}
						case Failure(e):
							Future.sync(Fail(e));
					}
				case Failure(e):
					Future.sync(Fail(e));
			});
		});
	}
	 
	function getChunk(s:Source, delim:Bytes):Surprise<Option<{ chunk:{ data: Header, rest: Source }, rest:Source }>, Error> {

		var split = s.split(delim);
		
		return split.a.parse(new HeaderParser(function (line, fields) {
				return
					Success(
						if (line == '--') null
						else {
							fields.push(HeaderField.ofString(line));
							new Header(fields);
						}
					);
			}))
				>> 
				function (o:{ data: Header, rest: Source }) 
					return 
					if (o.data == null) None
					else Some({ 
						chunk: o,
						rest: split.b,
					});
	}
}