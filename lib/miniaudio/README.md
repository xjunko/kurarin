# v-miniaudio
Vrap of the excellent [miniaudio](https://github.com/dr-soft/miniaudio) C audio library

# Status
The project is still highly work-in-progress and experimental, expect the API to change without warning.

Example `main.v`
```v
module main

import os
import math
import time

import miniaudio as ma

fn main() {

    wav_file := os.join_path(os.home_dir(),'test.wav')

    flac_file := os.join_path(os.home_dir(),'test.flac')

    mp3_file := os.join_path(os.home_dir(),'test.mp3')


    mut s1 := ma.sound(wav_file)
    mut s2 := ma.sound(flac_file)
    mut s3 := ma.sound(mp3_file)

    mut d := ma.device()
    // d.volume(0.5) // Set (master) volume for device

    d.add('sound id 1',s1)
    d.add('sound id 2',s2)
    d.add('sound id 3',s3)

    s1.play()
    time.sleep_ms(50)
    s3.play()
    time.sleep_ms(200)
    s3.seek(20)
    s2.play()

    // Fade out s1
    mut vol := 1.0
    for ee := s1.length(); ee > 0; ee = ee - 16.377 {
        vol = vol - 0.016
        s1.volume(vol)
        time.sleep_ms(16)
    }

    mut longest := int(math.max(s1.length(), s2.length()))
    longest = int(math.max(longest, s3.length()))
    time.sleep_ms(longest)

    d.free()

}
```
