# CloudFront
[CloudFront is a Content Delivery Network (CDN)](https://aws.amazon.com/es/cloudfront/) that allows you to store content in different places around the planet, and server that content to users closer to those places, reducing response times.
Amazon CloudFront only accepts well-formed connections and many types of invalid traffic, like *UDP floods*, *SYN floods* or *Slow Reads*, do not reach your application. So CloudFront is a great solution against DDoS attacs.

There are different ways in which you can use CloudFront. An example would be to store and server your images from CloudFront. To do that, you have to create a CloudFront distribution that provides you with a valid URL like *d5a6sd6ldjh.cloudfront.net*.
Then, create a DNS Alias like *images.example.com* that points to the distribution url. Finally, just change your application so every time we want to serve an image, instead of loading it from our domain, we load it from *images.example.com*.
When CloudFront receives the request, it checks if it already has that object and it's valid, in which case directly responds it. If it doesn't have it or the content is not valid anymore, it sends a request to the **Origin** and saves it before responding it to the client.

## Creating a CloudFront distribution
When you create a distribution to store and server content around the planet, you need the following parameters:
- **Origin Domain Name**: The DNS domain name of the Amazon S3 bucket or HTTP server from which you want CloudFront to get objects for this origin.
- **Origin Path**: If you want CloudFront to request your content from a directory in your Amazon S3 bucket or your custom origin, enter the directory path, beginning with a /. CloudFront appends the directory path to the value of Origin Domain Name.
- **Allowed HTTP Methods**: Methods not allowed will get a Not Allowed response.
- **Cached HTTP Methods**: Cacheable methods.
- **Forward Headers**: Whether or not to forward headers to the origin, which causes CloudFront to cache multiple versions of an object based on the values in one or more request headers. By default, CloudFront doesn't cache your objects based on the values in the request headers. You can create a white list of headers selecting the headers on which you want cloudFront to base caching. It doesn't consider the case of the header name, but it does consider the case of the header value. If you configure CloudFront to forward all headers to your origin, CloudFront doesn't cache the objects associated with this cache behavior. Instead, it sends every request to the origin.
- **TTL**: You can use Cache-Control or Expires headers, and CloudFront minimum, maximum, and default TTL values to control the amount of time in seconds that CloudFront keeps an object in the cache before forwarding another request to the origin. Default TTL is only used when Origin response has no cache headers (Cache-Control max-age, Cache-Control s-maxage, or Expires). Maximum TTL only applies when there are cache headers in the response coming from the Origin. Minimum and maximum limit whatever comes from Origin response headers. Client browser will use headers normally. [More info](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Expiration.html#ExpirationDownloadDist).
- **Forward Cookies**: Whether or not CloudFront cache your objects based on the Cookies.
- **Forward Query Strings**: Whether or not CloudFront cache your objects based on the query string. This could fragment the cache:: order of params, case sensitive, and so on.
- **Restrict Viewer Access**: Useful when serving private content. Amazon CloudFront provides two mechanisms to restrict access to content: Geo Restriction (which prevents access to your content from specific geographic locations) and Origin Access Identity (which is a special Amazon CloudFront user that has access to Amazon S3, but any other requests to S3 url’s would fail, so only CloudFront user has access).
- **Compress Objects Automatically**: Makes CloudFront to compress responses using gzip, when request contains the `Accept-Encoding: gzip` header. If the response was already compress in the Origin, CloudFront detects it and avoid re-compressing the content.
- **Price Class**: Which CDN's to use when serving content. Choosing more places is more expensive.
- **Alternate Domain Names**: Friendly DNS for CloudFront. You can even create subdomains.
- **SSL Certificate**: SSL Certificate to use. You have to save it on AWS.
- **Default Root Object**: What will be shown when someone goes to the root of your CloudFront distribution url.
- **Distribution State**: Enable or disable this distribution.

### Origins
When creating the distribution, you selected an **Origin**, which typically is our server, Load Balancer or S3 bucket. But we can choose more **Origins** for the same CloudFront distribution. When adding **Behaviours**, if the request matches with the chosen path for a particular **Behaviour**, the origin of that **Behaviour** will be used.

### Behaviours
When creating the distribution, a default **Behaviour** is assigned with the chosen configuration. You can create more **Behaviours** with different paths and order them. This way, CloudFront will try to match the request against all the **Behaviours** paths, one by one. If none matches, the default **Behaviour** will be used.

### Invalidating objects
You can set an object as invalid, so next request to that object will make CloudFront fetch it from the **Origin**. There is also object versioning.
[More info](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html).

### Reports
[You can see cache and user statistics in CloudWatch](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/reports.html).

## Exercise
Create a CloudFront distribution that has a new EC2 instance as **Origin**. Deploy the files in this repository following the steps in the `README` file.
Now, update the `index.php` file so instead of loading the image from the local path, it uses your CloudFront distribution.