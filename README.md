# BRIDGEBOARDS

### ABOUT

The code behind [bridgeboards.com](<http://bridgeboards.com/>).

[mywebary.com](http://mywebary.com) is a place where you can create a "gallery" of webpages, share, comment and browse them in a convinient way. When you provide a pair history URL to [bridgeboards.com](http://bridgeboards.com/) its contents are scrapped and the gallery is created automatically.

[bridgeboards.com](http://bridgeboards.com/) is managed by [kargal](https://github.com/kargal) and [me](https://github.com/johny-b), but feel free to launch your own better personalized bug-free version. 

All code improvements will be greatly appreciated.

### REQUIREMENTS

perl 5.26.1 (older versions will probably also be fine) + [Mojolicious](https://github.com/mojolicious/mojo/wiki/Installation)

### SYNOPSIS

```bash
$ sudo ./bridgeboards daemon -l http://*:80 
```

To make BBO hand history work one has to provide a working BBO login/password pair. Those are searched for in environment variables $BB_BBO_LOGIN and $BB_BBO_PASSWORD.

### GENERAL NOTE

The code was written long ago as a fun simple project that is now semi-abandoned. Most parts still work, or maybe are never used by anyone anymore.
