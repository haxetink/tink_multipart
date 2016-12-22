package tink.multipart;

import tink.io.Source;
import tink.http.Header;

typedef Chunk = {
	name:String,
	body:ChunkBody,
	?header:Header, // TODO: is this needed?
}

enum ChunkBody {
	Field(value:String);
	File(file:{filename:String, mimeType:String, content:Source});
}