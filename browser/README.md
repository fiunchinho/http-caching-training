# Browser HTTP Cache
There are two types of HTTP Caching:
- Expiration
- Validation

To test the examples in this repository, just start the built-in PHP server

```bash
$ php -S localhost:8000
```

## Expiration
### Expires
Check `expires.php` example.

### Cache-Control
Check `maxage.php` example.

## Validation
### ETag
Check `etag.php` example.

### Last-Modified
Check `modified.php` example.

## Sources
- [Things Caches Do](http://2ndscale.com/rtomayko/2008/things-caches-do)
- [HTTP Cache](https://symfony.com/doc/current/book/http_cache.html)
- [Caching Tutorial](https://www.mnot.net/cache_docs/)