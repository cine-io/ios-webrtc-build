# ios-webrtc-build

This repository contains script(s) to build WebRTC for iOS.

## Instructions

1. Clone this repository and `cd` into its directory.
2. Run `build.sh`.
3. Look in `build/dist` for the resulting libraries and executables.
4. Look in `build/build.log` if something goes wrong.

For example:

```bash
$ git clone git@github.com:cine-io/ios-webrtc-build.git
$ cd ios-webrtc-build
$ ./build.sh
```

## Notes

Because of the way the WebRTC project builds, the first time you run the
script it will take **A LONG TIME** to synchronize the code. That's because it
synchronizes the whole Chromium codebase. It's really annoying. Just be
patient (like, wait up to several *hours*) and hopefully things should work.

The script is meant to be idempotent. However, should you want to start over
from scratch, it's a simple matter of:

```bash
$ rm -rf src build depot_tools .build-config.sh
$ ./build.sh
```

## Status

Seems to be building, but I haven't yet figured out (a) which of the libraries
are needed, and (b) how to distribute these libraries. Considering making a
CocoaPod ... stay tuned!

## Acknowledgements

Inspired by: [this blog entry][webrtc-ios-howto] and [the project README][webrtc-ios-readme].


<!-- external links -->
[webrtc-ios-howto]:http://ninjanetic.com/how-to-get-started-with-webrtc-and-ios-without-wasting-10-hours-of-your-life/
[webrtc-ios-readme]:https://code.googlecom/p/webrtc/source/browse/trunk/talk/app/webrtc/objc/README
