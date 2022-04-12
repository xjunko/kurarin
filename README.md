## Info

With the recent addition of proper slider rendering, the updates will be way way slower than it used to be (maybe) since the slider rendering is the thing that kept this project from
finishing so yea....
## Preview

(Latest Preview)


https://user-images.githubusercontent.com/44401509/162553604-c6ac7c7b-246d-4344-bad5-b616bd7421ed.mp4


(Old: Proper video rendering straight from the program, can be enabled in settings.json)

https://user-images.githubusercontent.com/44401509/159376175-38ea4796-1906-439b-9304-2657b2772cd0.mp4


## Releases

You can get the latest development build from the CI/CD [here](https://github.com/FireRedz/kurarin/actions/workflows/ci.yml).

## Running

```bash
./kurarin [...arguments]
```
## Settings

The program will create the `settings.json` file on startup.


### Rendering

This program supports video renders. All you need to do is enable it in your
`settings.json` and install [FFmpeg](https://ffmpeg.org/) and add it to your $PATH.


## Building

### Requirements

* V
* BASS
* OpenGL >= 3.0

#### On Linux (Arch)

You might need to install a few library beforehand, [`libbass`](https://aur.archlinux.org/packages/libbass) and [`libbass_fx`](https://aur.archlinux.org/packages/libbass_fx). </br>

Then after that use the [`ext/build.sh`](https://github.com/FireRedz/kurarin/blob/rewrite/ext/build.sh) script to build, no makefile fuckery or something like that.
## Credits

Some of the code is _derived_ or literally copy-pasted from these projects, so big credits to them.

* [McOsu](https://github.com/McKay42/McOsu) by [McKay](https://github.com/McKay42)
* [danser-go](https://github.com/McKay42/McOsu) by [Wieku](https://github.com/Wieku)
* [osr2mp4](https://github.com/uyitroa/osr2mp4-core) by [yuitora](https://github.com/uyitroa)
* [opsu-dance](https://github.com/yugecin/opsu-dance) by [yugecin](https://github.com/yugecin)
