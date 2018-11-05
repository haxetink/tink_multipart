package tink.multipart;

import tink.io.Source;
import tink.streams.RealStream;
using tink.CoreApi;

interface Parser {
	function parse(source:IdealSource):RealStream<Parsed>;
}