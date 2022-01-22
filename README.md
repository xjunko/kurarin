# Kurarin - Nuked [Codename: Dementia]

i nuked literally everything and revamped (almost) the entire codebase...

## Disclaimer

note that this wont be usable (for public uses, although you can "hack" it to make it work) for awhile cuz im busy with school rn...

## Why Dementia

i cant keep up with the old codebase cuz its so bad so yea thats why

## Preview

* to be added

## Misc

### Build flags

By default most of these flags are disable to get the best performance out of the engine... although its unstable without it. (its still unstable even with the flags enabled :trollface:)

### Audio

Most of these are disabled cuz of creaking audio (prolly just a lunix thing) and offsync audio after playing it for awhile, could be fixed but i cba to do it for now...

* safe_audio [off]: use mutex when adding or mixing pcm frames (i dont really think this matter that much)
* mix_audio [off]: mix the pcm frames (without this, the hitsounds will overlap the music and itll sound retarded)

### Graphic

* no_aa [off]: no antialiasing for images
