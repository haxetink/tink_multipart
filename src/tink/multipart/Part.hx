package tink.multipart;

import tink.http.Header;
import tink.http.Message;
using tink.io.Source;

typedef Part = Message<Header, IdealSource>;