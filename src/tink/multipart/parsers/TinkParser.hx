package tink.multipart.parsers;

import haxe.io.Bytes;
import tink.multipart.Parser;
import tink.multipart.Chunk;
import tink.streams.RealStream;
import tink.http.Header;
import tink.http.StructuredBody;

using tink.io.Source;
using tink.CoreApi;

class TinkParser implements Parser {
	
	var boundary:String;
	
	public function new(boundary) {
		this.boundary = boundary;
	}
	
	public function parse(s:IdealSource):RealStream<Chunk> {
		var s = s.split(Bytes.ofString('--$boundary')).b;//TODO: make sure it's on its newline
		
		var delim = Bytes.ofString('\r\n--$boundary');
		
		return Stream.generate(function ():Future<StreamStep<Chunk>> {
			return getChunk(s, delim).flatMap(function (o) return switch o {
				case Success(None): 
					Future.sync(End);
				case Success(Some( { chunk: chunk, rest: rest } )): 
					s = rest; 
					switch chunk.data.byName('content-disposition') {
						case Success(v):
							chunk.rest.all().map(function(o) return switch o {
								case Success(bytes):
									var ext = v.getExtension();
									Data(new Named(
										ext['name'],
										switch ext['filename'] {
											case null: Value(bytes.toString());
											case filename: File(UploadedFile.ofBlob(filename, chunk.data.byName('content-type').orNull(), bytes));
										}
									));
								case Failure(e):
									Fail(e);
							});
						case Failure(e):
							Future.sync(Fail(e));
					}
				case Failure(e):
					Future.sync(Fail(e));
			});
		});
	}
	 
	function getChunk(s:IdealSource, delim:Bytes):Surprise<Option<{ chunk:{ data: Header, rest: IdealSource }, rest:IdealSource }>, Error> {

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