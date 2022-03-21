## Disclaimer

This is my personal side project so updates is very random.
## Preview

(Proper video rendering straight from the program, can be enabled in settings.json)

https://user-images.githubusercontent.com/44401509/159376175-38ea4796-1906-439b-9304-2657b2772cd0.mp4

(Slider is being reworked, so theres no alpha)

https://user-images.githubusercontent.com/44401509/159151243-650d9e88-eef8-4109-b25e-a17eb2f3530e.mp4

(Old)

https://user-images.githubusercontent.com/44401509/150633211-4424db2b-8cef-44a0-92a8-bafe7a9f33a1.mp4

## Releases

You can get the latest development build from the CI/CD [here](https://github.com/FireRedz/kurarin/actions/workflows/ci.yml).

## Running

```bash
./kurarin [...arguments]
```
## Settings

The file `settings.json` should be created at the program startup if it doesn't exist and it should looked like something below. (Not the value but the fields)
```json
{
  "window": {
    "speed": 1,
    "fps": 60,
    "record": true,
    "record_fps": 60,
    "audio_volume": 50,
    "effect_volume": 75,
    "overall_volume": 75
  },
  "gameplay": {
    "global_offset": 0,
    "lead_in_time": 0,
    "background_dim": 100,
    "disable_hitsound": false,
    "disable_hitobject": false,
    "disable_storyboard": false,
    "use_beatmap_hitsound": true,
    "disable_cursor": false,
    "cursor_size": 1,
    "cursor_trail_update_rate": 16.6667,
    "cursor_trail_length": 1000,
    "cursor_style": 2,
    "auto_update_rate": 16.6667
  },
  "miscellaneous": {
    "rainbow_hitcircle": true,
    "rainbow_slider": true,
    "scale_to_beat": true
  }
}
```

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


## TODOs

* Implement proper timing instead of relying on time.sleep (Ref: [Larpon's timing control](https://ptb.discord.com/channels/592103645835821068/713953140952530965/938000930622828625))
* Proper slider alpha (Ref: RenderTarget)
