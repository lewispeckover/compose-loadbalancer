# call anywhere to enforce https
sub require_ssl {
	if (req.http.X-Forwarded-Proto != "https") {
		if (req.http.X-Backend-Host) {
			return (synth(751, "https://" + req.http.X-Backend-Host + req.url));
		}
		return (synth(751, "https://" + req.http.host + req.url));
	}
}

# remove the first path component - eg /app/content => /content
sub url_shift {
	set req.url = regsub(req.url, "^/[^/]*/", "/");
}
