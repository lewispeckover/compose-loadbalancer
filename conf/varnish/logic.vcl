
sub vcl_recv {
	# limit our request methods because we're paranoid
	if (req.method !~ "^(GET|HEAD|PATCH|POST|DELETE|PUT|PURGE)$")
		return (synth(405, "Method Not Allowed"));
	}
	
	# only localhost can purge
	if (req.method == "PURGE" && client.ip ~ localhost) {
		return (purge);
	}

	# tell applications  if this was an https request (identified by server port)
        if (server.port == 81) {
                set req.http.X-Forwarded-Proto = "https";
        }

	# no point compressing these
	if (req.url ~ "(?i)(m4a|jpg|zip|apk|png|gif)$") {
		unset req.http.accept-encoding;
	}

	# normalise the querystring for cachey goodness
	set req.url = std.querysort(req.url);

	set req.backend_hint = consuldns.backend(regsuball(req.http.host, "[^a-zA-Z0-9]", "-") + ".service.consul");
}

sub vcl_backend_fetch {
	if (bereq.url ~ "(?i)(m4a|jpg|zip|apk|png|gif)$") {
		unset bereq.http.accept-encoding;
	}
}

sub vcl_pipe {
	# force the varnish -> backend connection to close, ensuring that headers that we set are sent with every request
	set bereq.http.connection = "close";
}

sub vcl_deliver {
	# show if it was served from cache or not
	if (obj.hits > 0) {
		set resp.http.X-Cache = "Hit";
	}
	else {
		set resp.http.X-Cache = "Miss";
	}
}

sub vcl_backend_response {
	# compress things for lazy backends
	if (beresp.http.content-type ~ "text" || beresp.http.content-type ~ "json") {
		set beresp.do_gzip = "yes";
	}
}

sub vcl_hash {
	# make sure we distinguish between http and non-https caches
	if (req.http.X-Forwarded-Proto) {
		hash_data(req.http.X-Forwarded-Proto);
	}
}

sub require_ssl {
	# this helper function can be called anywhere to enforce https
	if (req.http.X-Forwarded-Proto != "https") {
		if (req.http.X-Backend-Host) {
			return (synth(751, "https://" + req.http.X-Backend-Host + req.url));
		}
		return (synth(751, "https://" + req.http.host + req.url));
	}
}

sub url_shift {
	# remove the first path component
	set req.url = regsub(req.url, "^/[^/]*/", "/");
}
