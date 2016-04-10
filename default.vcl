vcl 4.0;


sub devicedetect {
    unset req.http.X-UA-Device;
    set req.http.X-UA-Device = "pc";

    # Handle that a cookie may override the detection alltogether.
    if (req.http.Cookie ~ "(?i)X-UA-Device-force") {
        /* ;?? means zero or one ;, non-greedy to match the first. */
        set req.http.X-UA-Device = regsub(req.http.Cookie, "(?i).*X-UA-Device-force=([^;]+);??.*", "\1");
        /* Clean up our mess in the cookie header */
        set req.http.Cookie = regsuball(req.http.Cookie, "(^|; ) *X-UA-Device-force=[^;]+;? *", "\1");
        /* If the cookie header is now empty, or just whitespace, unset it. */
        if (req.http.Cookie ~ "^ *$") { unset req.http.Cookie; }
    } else {
        if (req.http.User-Agent ~ "\(compatible; Googlebot-Mobile/2.1; \+http://www.google.com/bot.html\)" ||
            (req.http.User-Agent ~ "iPhone" && req.http.User-Agent ~ "\(compatible; Googlebot/2.1; \+http://www.google.com/bot.html")) {
            set req.http.X-UA-Device = "mobile-bot"; }
        elsif (req.http.User-Agent ~ "(?i)(ads|google|bing|msn|yandex|baidu|ro|career|seznam|)bot" ||
            req.http.User-Agent ~ "(?i)(baidu|jike|symantec)spider" ||
            req.http.User-Agent ~ "(?i)scanner" ||
            req.http.User-Agent ~ "(?i)(web)crawler") {
            set req.http.X-UA-Device = "bot"; }
        elsif (req.http.User-Agent ~ "(?i)ipad")        { set req.http.X-UA-Device = "tablet-ipad"; }
        elsif (req.http.User-Agent ~ "(?i)ip(hone|od)") { set req.http.X-UA-Device = "mobile-iphone"; }
        /* how do we differ between an android phone and an android tablet?
           http://stackoverflow.com/questions/5341637/how-do-detect-android-tablets-in-general-useragent */
        elsif (req.http.User-Agent ~ "(?i)android.*(mobile|mini)") { set req.http.X-UA-Device = "mobile-android"; }
        // android 3/honeycomb was just about tablet-only, and any phones will probably handle a bigger page layout.
        elsif (req.http.User-Agent ~ "(?i)android 3")              { set req.http.X-UA-Device = "tablet-android"; }
        /* Opera Mobile */
        elsif (req.http.User-Agent ~ "Opera Mobi")                  { set req.http.X-UA-Device = "mobile-smartphone"; }
        // May very well give false positives towards android tablets. Suggestions welcome.
        elsif (req.http.User-Agent ~ "(?i)android")         { set req.http.X-UA-Device = "tablet-android"; }
        elsif (req.http.User-Agent ~ "PlayBook; U; RIM Tablet")         { set req.http.X-UA-Device = "tablet-rim"; }
        elsif (req.http.User-Agent ~ "hp-tablet.*TouchPad")         { set req.http.X-UA-Device = "tablet-hp"; }
        elsif (req.http.User-Agent ~ "Kindle/3")         { set req.http.X-UA-Device = "tablet-kindle"; }
        elsif (req.http.User-Agent ~ "Touch.+Tablet PC" ||
            req.http.User-Agent ~ "Windows NT [0-9.]+; ARM;" ) {
                set req.http.X-UA-Device = "tablet-microsoft";
        }
        elsif (req.http.User-Agent ~ "Mobile.+Firefox")     { set req.http.X-UA-Device = "mobile-firefoxos"; }
        elsif (req.http.User-Agent ~ "^HTC" ||
            req.http.User-Agent ~ "Fennec" ||
            req.http.User-Agent ~ "IEMobile" ||
            req.http.User-Agent ~ "BlackBerry" ||
            req.http.User-Agent ~ "BB10.*Mobile" ||
            req.http.User-Agent ~ "GT-.*Build/GINGERBREAD" ||
            req.http.User-Agent ~ "SymbianOS.*AppleWebKit") {
            set req.http.X-UA-Device = "mobile-smartphone";
        }
        elsif (req.http.User-Agent ~ "(?i)symbian" ||
            req.http.User-Agent ~ "(?i)^sonyericsson" ||
            req.http.User-Agent ~ "(?i)^nokia" ||
            req.http.User-Agent ~ "(?i)^samsung" ||
            req.http.User-Agent ~ "(?i)^lg" ||
            req.http.User-Agent ~ "(?i)bada" ||
            req.http.User-Agent ~ "(?i)blazer" ||
            req.http.User-Agent ~ "(?i)cellphone" ||
            req.http.User-Agent ~ "(?i)iemobile" ||
            req.http.User-Agent ~ "(?i)midp-2.0" ||
            req.http.User-Agent ~ "(?i)u990" ||
            req.http.User-Agent ~ "(?i)netfront" ||
            req.http.User-Agent ~ "(?i)opera mini" ||
            req.http.User-Agent ~ "(?i)palm" ||
            req.http.User-Agent ~ "(?i)nintendo wii" ||
            req.http.User-Agent ~ "(?i)playstation portable" ||
            req.http.User-Agent ~ "(?i)portalmmm" ||
            req.http.User-Agent ~ "(?i)proxinet" ||
            req.http.User-Agent ~ "(?i)sonyericsson" ||
            req.http.User-Agent ~ "(?i)symbian" ||
            req.http.User-Agent ~ "(?i)windows\ ?ce" ||
            req.http.User-Agent ~ "(?i)winwap" ||
            req.http.User-Agent ~ "(?i)eudoraweb" ||
            req.http.User-Agent ~ "(?i)htc" ||
            req.http.User-Agent ~ "(?i)240x320" ||
            req.http.User-Agent ~ "(?i)avantgo") {
            set req.http.X-UA-Device = "mobile-generic";
        }
    }
}




backend default {
    .host = "app";
    .port = "80";
}


sub vcl_recv {
    if (req.http.x-forwarded-for) {
        set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
    } else {
        set req.http.X-Forwarded-For = client.ip;
    }
    call devicedetect;
}

sub vcl_deliver {
    set resp.http.X-Forwarded-For = client.ip;
    set resp.http.X-UA-Device = req.http.X-UA-Device;
}

sub vcl_backend_response {
    set beresp.do_esi = true; // Do ESI processing
}











