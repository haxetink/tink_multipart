package tink.multipart;

import tink.io.IdealSource;
import tink.streams.Stream;

interface Parser {
	function parse(source:IdealSource):Stream<Chunk>;
}