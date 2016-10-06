sub vcl_init {
	new consuldns = dynamic.director(
		port = "80",
		ttl = 1s);
}
