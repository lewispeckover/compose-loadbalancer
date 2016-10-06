backend default {
	.host = "127.0.0.1";
	.port = "1";
}
sub vcl_init {
	new consuldns = dynamic.director(
		port = "80",
		ttl = 1s);
}
