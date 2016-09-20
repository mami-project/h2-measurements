# H2 TOOL
Script to test bunch of H2-related functionalities against a target URL

## Installation
Apart from basic requirements (timeout, getent, etc.) the script also needs <<OpenSSL 1.0.2d>> (or higher) — for ALPN support. I have provided a script <<openssl-setup.sh>> which will install the specific version we need and “patch” it with my own version of “s_clie    nt” which is faster than the one provided by OpenSSL — since it limits its work to what is needed for this test. Openssl should get installed at “/usr/local/ssl/bin/“; otherwise, you need to adjust the path in <<h2-tool.sh>>. The tool also uses <<geoiplookup>> (Maxm    ind) to get country and AS number of the IP associated to a given domain — this is optional, script will skip it if not available.

## Usage
$ ./h2-tool.sh google.com 1
[./h2-tool.sh][1474387783]  Testing URL: google.com IP: 216.58.210.142 Country: US Org: Google Inc. AS: AS15169
[./h2-tool.sh][1474387783]  Testing ALPN!
[./h2-tool.sh][1474387783]  ALPN Result: ALPN: h2 Duration 55 ms. New timeout is: 1 sec
[./h2-tool.sh][1474387783]  Testing NPN!
[./h2-tool.sh][1474387783]  NPN Result: NPN: h2 spdy/3.1 http/1.1 Duration 34 ms
[./h2-tool.sh][1474387783]  Testing H2C
[./h2-tool.sh][1474387783]  H2C Result: h2clear=FAILED Duration 12 ms
google.com 216.58.210.142 Google Inc. US AS15169 ALPN: h2 55 ms NPN: h2 spdy/3.1 http/1.1 34 ms h2clear=FAILED 12 ms
[./h2-tool.sh][1474387783]  Test duration: 1474387783

Or as follows for less output:

$ ./h2-tool.sh google.com
google.com 216.58.211.206 Google Inc. US AS15169 ALPN: h2 51 ms NPN: h2 spdy/3.1 http/1.1 40 ms h2clear=FAILED 12 ms

The output it provides is as follows:

URL IP ORGANIZATION COUNTRY ASNUM ALPN-INFO ALPN-DURATION NPN-INFO NPN-DURATION H2-CLEAR-INFO H2-CLEAR-DURATION

Cheers,
MV
## Contributing
1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## Credits
Matteo Varvello, Telefonica Research 