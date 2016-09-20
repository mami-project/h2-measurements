# H2 TOOL
Script to test bunch of H2-related functionalities against a target URL

## Installation
Apart from basic requirements (timeout, getent, etc.) the script also needs "OpenSSL 1.0.2d" (or higher) — for ALPN support. I have provided a script "openssl-setup.sh" which will install the specific version we need and “patch” it with my own version of “s_clie    nt” which is faster than the one provided by OpenSSL — since it limits its work to what is needed for this test. Openssl should get installed at “/usr/local/ssl/bin/“; otherwise, you need to adjust the path in "h2-tool.sh". The tool also uses "geoiplookup" (Maxm    ind) to get country and AS number of the IP associated to a given domain — this is optional, script will skip it if not available.

## Usage
$ `./h2-tool.sh google.com 1`

Or as follows for less output:

$ `./h2-tool.sh google.com`

The output it provides is as follows:

`URL IP ORGANIZATION COUNTRY ASNUM ALPN-INFO ALPN-DURATION NPN-INFO NPN-DURATION H2-CLEAR-INFO H2-CLEAR-DURATION`

## Contributing
1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## Credits
Matteo Varvello, Telefonica Research 

Kyle Schomp, Akamai
