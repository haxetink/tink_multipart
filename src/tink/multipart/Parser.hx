package tink.multipart;

import tink.io.IdealSource;
import tink.streams.Stream;

interface Parser {
	public function parse(source:IdealSource):Stream<Chunk>;
}