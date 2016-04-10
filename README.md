# Varnish Cache
## Configuration files
Varnish will read a config file where we can define the behaviour for Varnish. This file is typically in `/etc/sysconfig/varnish`. The two most important configurations there are `VARNISH_VCL_CONF` and `VARNISH_LISTEN_PORT`, that will tell varnish where it can find the rest of the configuration and in which port will respond http requests.

The file specified in `VARNISH_VCL_CONF` contains VLC code: the varnish programming language. There we will tell Varnish how to behave. Open the file with your editor so you can edit it and remember to always restart varnish after every change you make. If the varnish service won't start, you can try to start it manually using this command `varnishd -C -f /etc/varnish/default.vcl`, and it will output potential errors.

## VCL Language
VCL has if and else statements. Nested logic can be implemented with the elseif statement. There are no loops or iterators of any kind in VCL.

The following operators are available in VCL:

- **=** Assignment operator.
- **==** Comparison.
- **~** Match. Can either be used with regular expressions or ACLs.
- **!** Negation.
- **&&** Logical and.
- **||** Logical or.


## Configuring our backend
A backend server is the server providing the content Varnish will accelerate.

Our first task is to [tell Varnish where it can find its backends](https://www.varnish-cache.org/docs/4.0/reference/vcl.html#backend-definition):

````
backend default {
    .host = "127.0.0.1";
    .port = "80";
}
````

This means that the real backend that renders responses is listening on port 80 (apache in our case). If we visit a page in our server, Apache will respond, but if we go to the Varnish port (8080 unless we change it), we'll get the response coming through Varnish.

Do you see any difference in both responses? Don't forget the headers!

## Switching ports
Change Apache and Varnish configurations so that Apache listens in port 8080 and Varnish listens on port 80, so all your requests go through Varnish.


## Varnish headers
The X-Varnish HTTP header allows you to find the correct log-entries for the transaction. For a cache hit, X-Varnish will contain both the ID of the current request and the ID of the request that populated the cache. It makes debugging Varnish a lot easier.

Varnish adds an `Age` header to indicate how long the object has been kept inside Varnish. Varnish will fetch the object from the backend when `Age` is higher than the specified TTL. The `Age` value could be higher than the TTL specified if no requests have come recently.


## Varnish subroutines
When a request reaches a Varnish server, there is an execution flow with different steps called subroutines that get executed in an specific order. You can see all the varnish flow here [http://book.varnish-software.com/4.0/_images/simplified_fsm.svg](http://book.varnish-software.com/4.0/_images/simplified_fsm.svg).

There are several important methods and objects that you need to be aware of. [Methods have a default implementation](https://www.varnish-cache.org/trac/browser/bin/varnishd/builtin.vcl), and if you define one of these methods in your VCL file, both the default implementation and your own will be executed, unless we use the return statement, in which case only our implementation gets executed.

Important subroutines are:

- **vcl_recv**: Called at the beginning of a request, after the complete request has been received and parsed. Its purpose is to decide whether or not to serve the request, how to do it, and, if applicable, which backend to use. It is also used to modify the request, something you'll probably find yourself doing frequently.

- **vcl_hash**: Called after vcl_recv to create a hash value for the request. This is used as a key to look up the object in Varnish.

- **vcl_hit**: Called when a cache lookup is successful.

- **vcl_miss**: Called after a cache lookup if the requested document was not found in the cache. Its purpose is to decide whether or not to attempt to retrieve the document from the backend, and which backend to use.

- **vcl_backend_fetch**: Called before sending the request to the backend. In this subroutine you typically alter the request before it gets to the backend.

- **vcl_backend_response**: Called after the response has been successfully retrieved from the backend.

- **vcl_deliver**: Called before a cached object is delivered to the client.

- **vcl_pass**: Called upon entering pass mode. We use pass when we don't want to cache.

- **vcl_pipe**: Called upon entering pipe mode. Pipe mode is using for streaming.

Depending on the subroutine, these variable objects can be accessed and manipulated:

- **req**: The request object. When Varnish has received the request the `req` object is created and populated. Most of the work you do in vcl_recv you do on or with the `req` object.

- **bereq**: The backend request object. Varnish contructs this before sending it to the backend. It is based on the `req` object.

- **beresp**: The backend response object. It contains the headers of the object coming from the backend. If you want to modify the response coming from the server you modify this object in `vcl_backend_response`.

- **resp**: The HTTP response right before it is delivered to the client. It is typically modified in `vcl_deliver`.

- **obj**: The object as it is stored in cache. Read only.

These variable objects [contain request and response information](https://www.varnish-cache.org/docs/4.0/reference/vcl.html#variables).

## Adding custom headers
To add a HTTP header, unless you want to add something about the client/request, it is best done in `vcl_backend_response` as this means it will only be processed every time the object is fetched:

````
sub vcl_backend_response {
  # Add custom header:
  set beresp.http.Foo = "bar";
}
````

Let's add some debug headers, so we can easily see when the response is coming from cache or not.
````
sub vcl_deliver {
    if ( obj.hits > 0 ) {
        set resp.http.X-Cache = "HIT";
    }else{
        set resp.http.X-Cache = "MISS";
    }

    # And add the number of hits in the header:
    set resp.http.X-Cache-Hits = obj.hits;
}
````
Restart Varnish and see what you get.

We still need to do things based on the client IP, so if all requests come from Varnish we need a way to receive the client IP in the backend. Let's also remove some useless headers and add a new header telling whether the request came from a desktop or mobile device.

````
sub vcl_deliver {
    # Add real client ip to a header
    set resp.http.X-Forwarded-For = client.ip;

    if (req.http.User-Agent ~ "(?i)mobile" {
        set req.http.X-Device = "mobile";
    }else{
        set req.http.X-Device = "desktop";
    }

    # Remove some headers: Apache version & OS
    unset resp.http.X-Powered-By;
    unset resp.http.Server;
}
````

## Setting the TTL using HTTP headers
The 'Cache-Control' header instructs caches how to handle the content. Varnish cares about the `max-age` parameter and uses it to calculate the TTL for an object.

So make sure you issue a 'Cache-Control' header with a max-age header.

## Setting the TTL in Varnish
Sometimes you want a more generic way to set the TTL of a response. You can do it directly on Varnish.

````
sub vcl_backend_response {
    set beresp.ttl = 30s;
}
````

This doesn't change the `Cache-Control` header. This can still be used by browsers and other public caches.

## Cookies and Authorization
If Varnish sees an `Authorization` header it will pass the request directly to the backend. If this is not what you want you can unset the header.

In the default configuration, Varnish will not cache a response coming from the backend with a `Set-Cookie` header present. Also, if the client sends a `Cookie` header, Varnish will bypass the cache and go directly to the backend.

### Removing cookies
This can be overly conservative. A lot of sites use Google Analytics (GA) to analyze their traffic. GA sets a cookie to track you. This cookie is used by the client side javascript and is therefore of no interest to the server.
We can remove these cookies on Varnish:

````
sub vcl_recv {
    # Removes all cookies named __utm? (utma, utmb...)
    if (req.http.Cookie)
    {
        set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "_gat=[^;]+(; )?", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "utmctr=[^;]+(; )?", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "utmcmd.=[^;]+(; )?", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "utmccn.=[^;]+(; )?", "");

        # Are there cookies left with only spaces or that are empty?
        if (req.http.cookie ~ "^\s*$") {
            unset req.http.cookie;
        }
    }
}
````

## Vary header
A lot of the response headers tell the client something about the HTTP object being delivered. Clients can request different variants of a HTTP object, based on their preference. Their preferences might cover stuff like encoding or language. When a client prefers UK English this is indicated through Accept-Language: en-uk. Caches need to keep these different variants apart and this is done through the HTTP response header `Vary`.

When a backend server issues a `Vary: Accept-Language` it tells Varnish that its needs to cache a separate version for every different `Accept-Language` that is coming from the clients.

If two clients say they accept the languages "en-us, en-uk" and "da, de" respectively, Varnish will cache and serve two different versions of the page if the backend indicated that Varnish needs to vary on the `Accept-Language` header.

Please note that the headers that `Vary` refer to need to match exactly for there to be a match. So Varnish will keep two copies of a page if one of them was created for "en-us, en-uk" and the other for "en-us,en-uk". Just the lack of a whitespace will force Varnish to cache another version.

To achieve a high hitrate whilst using Vary is there therefore crucial to normalize the headers the backends varies on. Remember, just a difference in casing can force different cache entries.

The following VCL code will normalize the `Accept-Language` header to either "en", "de" or "fr", in this order of precedence:

````
if (req.http.Accept-Language) {
    if (req.http.Accept-Language ~ "en") {
        set req.http.Accept-Language = "en";
    } elsif (req.http.Accept-Language ~ "de") {
        set req.http.Accept-Language = "de";
    } elsif (req.http.Accept-Language ~ "fr") {
        set req.http.Accept-Language = "fr";
    } else {
        # unknown language. Remove the accept-language header and
        # use the backend default.
        unset req.http.Accept-Language
    }
}
````

## Edge Side Includes
Edge Side Includes is a language to include fragments of web pages in other web pages. Think of it as HTML include statement that works over HTTP. In order for this to work, we need to tell varnish to allow ESI:
````
sub vcl_backend_response
{
        set beresp.do_esi = true; // Do ESI processing
}
````

For example: We want to show one cacheable page showing an almost static content and caching them 100 seconds. The problem here is that we need to show the current time in each response.
````
<?php

$now = time();
$expiration = $now + 100;

$expiration_seconds = $expiration - $now;
$expiration_date = gmdate( 'D, d M Y H:i:s',  $expiration ).' GMT';

header( 'Expires: '.$expiration_date);
header( 'Cache-Control: public,max-age='.$expiration_seconds );

?>
<html>
<body>
The time is: <?php echo gmdate( 'D, d M Y H:i:s' ); ?> at this very moment.
</body>
</html>
````

We can separate the changing part into another script and request it by ESI:
````
<?php

$now = time();
$expiration = $now + 100;

$expiration_seconds = $expiration - $now;
$expiration_date = gmdate( 'D, d M Y H:i:s',  $expiration ).' GMT';

header( 'Expires: '.$expiration_date);
header( 'Cache-Control: public,max-age='.$expiration_seconds );

?>
<html>
<body>
Cached time is: <?php echo gmdate( 'D, d M Y H:i:s' ); ?>
</br>
The time is: <esi:include src="/date.php" /> at this very moment.
</body>
</html>
````
Notice that we've changed the direct call to show the current time to another php script. Let's create the script that responsd to that request:

````
<?php
$now = time();
$expiration = $now;

$expiration_seconds = $expiration - $now;
$expiration_date = gmdate( 'D, d M Y H:i:s',  $expiration ).' GMT';

header( 'Expires: '.$expiration_date);
header( 'Cache-Control: public,max-age='.$expiration_seconds );

echo gmdate( 'D, d M Y H:i:s' );
?>
````

Restar varnish and check if the behaviour has changed.

## Multiple backends and Health checks
You can [setup several backends in Varnish](https://www.varnish-cache.org/docs/trunk/users-guide/vcl-backends.html#multiple-backends), but these backends could fail at any moment. Varnish can maintain a list of healthy backends depending on some criteria given for us, so it could send request only to healthy backends.

[Probes will query the backend](https://www.varnish-cache.org/docs/4.0/reference/vcl.html#probes) for status on a regular basis and mark the backend as down it they fail.

````
backend default {
    .host = "192.168.99.100";
    .port = "8081";

    .probe = {
        # Health check to perform
        .request =
          "GET / HTTP/1.1"
          "Host: 192.168.99.100:8081"
          "Connection: close"
          "User-Agent: Varnish Health Probe";

        .interval  = 5s; # check the health of each backend every 5 seconds
        .timeout   = 1s; # timing out after 1 second.
        .window    = 5;  # If 3 out of the last 5 polls succeeded the backend is considered healthy, otherwise it will be marked as sick
        .threshold = 3;
    }
}
````

## ACL
[An Access Control List (ACL)](https://www.varnish-cache.org/docs/4.0/reference/vcl.html#access-control-list-acl) declaration creates and initialises a named Access Control List which can later be used to match client addresses.

````
acl localnetwork {
    "localhost";    # myself
    "192.0.2.0"/24; # and everyone on the local network
    ! "192.0.2.23"; # except for the dial-in router
}
````

To match an IP address against an ACL, simply use the match operator:
````
if (client.ip ~ localnetwork) {
    return (pipe);
}
````

## Purging
[A purge](https://www.varnish-cache.org/docs/trunk/users-guide/purging.html) is what happens when you pick out an object from the cache and discard it along with its variants. Usually a purge is invoked through HTTP with the method PURGE.
Normally, you'd want to check if the client performing the PURGE has the right permissions (meaning, is in some ACL), and in that case, execute the action

````
acl purge {
    "localhost";
    "192.168.55.0"/24;
}

sub vcl_recv {
    # allow PURGE from localhost and 192.168.55...

    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return(synth(405,"Not allowed."));
        }
        return (purge);
    }
}
````

## Stale-While-Revalidate
You can [set up Varnish to serve stale content while the backend is down](https://www.varnish-cache.org/docs/4.0/users-guide/vcl-grace.html), so your users don't even notice that something is wrong. This strategy is called Stale-While-Revalidate, and the Varnish feature that allows us to implement it is called Grace.


## Hash Normalization
- https://www.varnish-cache.org/docs/trunk/reference/vmod_std.generated.html#func-querysort

# Further reading
- https://www.varnish-cache.org/docs/4.0/tutorial/index.html#tutorial-index
- https://www.varnish-cache.org/docs/4.0/users-guide/index.html#users-guide-index
- https://www.varnish-cache.org/trac/browser/bin/varnishd/builtin.vcl?rev=4.0
- http://book.varnish-software.com/4.0/chapters/HTTP.html