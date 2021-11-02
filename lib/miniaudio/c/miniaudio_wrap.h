//#include <stdio.h>

/*
void data_callback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount)
{
    ma_decoder* pDecoder = (ma_decoder*)pDevice->pUserData;
    if (pDecoder == NULL) {
        return;
    }

    ma_decoder_read_pcm_frames(pDecoder, pOutput, frameCount);

    (void)pInput;
}
*/

/*
ma_uint32 read_and_mix_pcm_frames_f32(ma_decoder* pDecoder, void* pOutput_F32, ma_uint32 frameCount)
{
    int CHANNEL_COUNT = 2;
    float* pOutputF32 = (float*)pOutput_F32;

    //The way mixing works is that we just read into a temporary buffer, then take the contents of that buffer and mix it with the
    //contents of the output buffer by simply adding the samples together. You could also clip the samples to -1..+1, but I'm not
    //doing that in this example.

    float temp[4096];
    ma_uint32 tempCapInFrames = ma_countof(temp) / CHANNEL_COUNT;
    ma_uint32 totalFramesRead = 0;

    while (totalFramesRead < frameCount) {
        ma_uint32 iSample;
        ma_uint32 framesReadThisIteration;
        ma_uint32 totalFramesRemaining = frameCount - totalFramesRead;
        ma_uint32 framesToReadThisIteration = tempCapInFrames;
        if (framesToReadThisIteration > totalFramesRemaining) {
            framesToReadThisIteration = totalFramesRemaining;
        }

        framesReadThisIteration = (ma_uint32)ma_decoder_read_pcm_frames(pDecoder, temp, framesToReadThisIteration);
        if (framesReadThisIteration == 0) {
            break;
        }

        // Mix the frames together.
        for (iSample = 0; iSample < framesReadThisIteration*CHANNEL_COUNT; ++iSample) {
            pOutputF32[totalFramesRead*CHANNEL_COUNT + iSample] += temp[iSample];
        }

        totalFramesRead += framesReadThisIteration;

        if (framesReadThisIteration < framesToReadThisIteration) {
            break;
        }
    }

    return totalFramesRead;
}
*/