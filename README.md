<div style="float: right; text-align: center;">
    <div>
        <img width="200" align="right" style="float: right; margin: 0 10px 0 0;" alt="Kurarin" src="assets/textures/kurarin.png">
    </div>
    <a align="right" style="text-decoration: none; font-size: 10px; float: right; margin: 0 10px 0 0;" href="https://youtu.be/2b1IexhKPz4"> Image is courtesy of Iyowa </a>
</div>

## Disclaimer

This program is far from finished and it's not exactly stable either but it works most of the time. <br/>
Use [danser-go](https://github.com/Wieku/danser-go) or [McOsu](https://github.com/McKay42/McOsu), if you're looking for client alternative.

## Preview

[Here](PREVIEWS.md)

## Releases

~~You can get the latest development build from the CI/CD
[here](https://github.com/FireRedz/kurarin/actions/workflows/ci.yml).~~ <br />
Build CI is dead rn, [build it yourself](#building) for now.

## Running

```bash
./kurarin [...arguments]
```

## Settings

The program will create a `settings.json` file on startup for the first time, and exit right after. <br/>
The next startup will be normal.

## Features

Currently supports:

* Gameplay (ripped off from danser)
* Auto (If launched without the -play flag)
* Rendering (abit primitive rn but it works, make sure you got [FFmpeg](https://ffmpeg.org/) installed)
* Storyboard ("works")
* and more idk bruh

WIP:

* User interface (Can be enabled with --ui flag.)

TODO:

* TODO

## Building

### Requirements

* V
* GCC/Clang
* OpenGL 3.3

#### Linux

By default, the program will be built with VSYNC enabled, so max FPS is 60. I will add a patch for this eventually. <br/>
Tested with Arch but it _should_ work elsewhere as long as it's linux.

Use [`ext/build.sh`](https://github.com/FireRedz/kurarin/blob/rewrite/ext/build.sh) to build the program, no makefile
fuckery or smth like that.

## Credits

Some of the code is _derived_ or literally copy-pasted from these projects, so big credits to them.

* [McOsu](https://github.com/McKay42/McOsu) by [McKay](https://github.com/McKay42)
* [danser-go](https://github.com/Wieku/danser-go) by [Wieku](https://github.com/Wieku)
* [osr2mp4](https://github.com/uyitroa/osr2mp4-core) by [yuitora](https://github.com/uyitroa)
* [opsu-dance](https://github.com/yugecin/opsu-dance) by [yugecin](https://github.com/yugecin)
