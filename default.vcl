vcl 4.0;

backend default {
    .host = "app";
    .port = "80";
}


sub vcl_deliver {
    set resp.http.X-Forwarded-For = client.ip;
}

