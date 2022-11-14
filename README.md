# v1.1Programmatic Parallels of Signal Flow

&nbsp;&nbsp;&nbsp;&nbsp;Signal flow is something I find endlessly fascinating. The process of receiving input, processing it, and returning output is relatively easy to understand as a concept. But its implementation is so ubiquitous that you can look almost anywhere in the universe for examples. Breathing, cooking, war, photosynthesis, evolution, art, comedy, legislation, raising kids - these are all examples of interacting with a set of given inputs and returning an output.

&nbsp;&nbsp;&nbsp;&nbsp;Since I started programming, I’ve been looking for ways to express other examples of this process through the lens of coding to better understand what it is I’m actually doing on a day-to-day basis. As a former recording studio engineer, I thought it would be fun to take a more programmatic look at audio signal flow and the environment in which it’s created (the recording studio). My goal is to discuss parallels between the worlds of software development and the recording studio so that software devs and audio folks can better understand each others’ process through their respective disciplines.

<br/>

## **Signal Path**

&nbsp;&nbsp;&nbsp;&nbsp;Before digging in, I’d like to point out that [the pipeline operator in Elixir ( |> ) ]([https://hexdocs.pm/elixir/operators.html#general-operators](https://hexdocs.pm/elixir/operators.html#general-operators)) works essentially like a *normalled* patch bay. It connects inputs and outputs without having to explicitly pass its return value as the next argument. Similarly, when patch bays are normalled and thoughtfully laid out, we don’t even have to use patch cables.

&nbsp;&nbsp;&nbsp;&nbsp;For example, normalled patchbays are typically laid out in two rows: outputs on the top row and inputs on the bottom row. The general workflow of patchbays is almost invariably top to bottom. If they are normalled, the output on the top row is connected to the respective input on the back of the patchbay, which allows us to pass the **output** signal of one module (i.e., a mic pre-amplifier) to the **input** of another module (i.e., a compressor) without having to connect them on the front side with a patch cable. With this option, recording engineers can thoughtfully design a patchbay bespoke to their specific setup, minimizing the use of patch cables from the source signal to its final destination.

&nbsp;&nbsp;&nbsp;&nbsp;The pipeline operator in elixir works in a similar way. If all the functions in the chain are programmed to take the same variable as their first argument, we can use the pipeline operator to implicitly pass that argument through the chain of functions without having to repeatedly add it to each function call.

&nbsp;&nbsp;&nbsp;&nbsp;Now we’ll take a look at the path of a sound source (the input), its various manipulations through the recording process, and finally playback through speakers (the output) from a programmatic perspective using the pipeline operator in Elixir syntax.

_Disclaimer: this is mock code only used to demonstrate audio signal manipulation through Elixir syntax. For the sake of expedience, I’ll be using functions that are clearly named, but not all explicitly documented._

```elixir
defmodule SignalPath do

import AudioSignal.{AudioSignal, AudioSignals}

# in decibels
@gain_amount = 40,
# some map of tuples {:frequency, :gain}
@eq_changes = {{60, 2}, {315, -4}, {2_500, -2}, {12_000, 1}},
# in decibels
@threshold = 50,
# numerator
@ratio = 2,
# in milliseconds
@delay_time = 225,
# in decibels
@gain_offset = 10
# in decibels
@feedback = 5
# in decibels
@playback_volume = 55

def create_signal_path(%AudioSignal{} = audio_signal) do
  audio_signal
    |> microphone()
    |> pre_amplifier(@gain_amount)
    |> equalizer(@eq_changes)
    |> compressor(@threshold, @ratio)
    |> send_to_echo(@delay_time, @gain_offset, @feedback)
    |> record_audio()
    |> playback(@playback_volume)
  end
end

```

## **The Sound Source**

&nbsp;&nbsp;&nbsp;&nbsp;Before sound is recorded, it must be created. All sounds are essentially vibrations of air molecules at specific frequencies and amplitudes. That’s how sound is created and also how we perceive it (unless we’re actually **looking** at sonographic data). Let’s start with the example of a vocalist singing a melody. The simple explanation is that a vocalist pushes air from the lungs past the vocal cords, which vibrate even more air molecules to manipulate pitch and volume.

Below is a very basic schema for an audio signal and sound wave.

```elixir

defmodule AudioSignal do
  @type t :: %__MODULE__{
    signal_type: String.t(),
    gain: integer(),
    frequency_profile: Wave.t()
  }

  defstruct [:signal_type, :gain, :frequency_profile]
end

defmodule Wave do
  @type t :: %__MODULE__{
    frequency: integer(),
    gain: integer()
  }

  defstruct [{:frequency, :gain}]
end
```

## **Microphone**


&nbsp;&nbsp;&nbsp;&nbsp;Microphones take acoustic sounds and convert them to analog electrical audio signals. They do this by using elements such as diaphragms, condensers, or metallic ribbons, which reverberate from an incoming sound source (like the sound of our vocalist) and use electromagnetism to convert that air pressure into an analog electrical signal. The amplification level is now the measure of voltage of this signal. It’s called gain, which can be thought of as the electrical expression of volume.

```elixir
def microphone(%AudioSignal{signal_type: "acoustic"} = audio_signal) do
  audio_signal
  |> convert_to_analog()
  |> Map.put(:signal_type, "mic")
end
```

## **Pre-amplifier**

&nbsp;&nbsp;&nbsp;&nbsp;A mic preamplifier (or preamp) is an amplifying circuit designed to boost a mic level input to a line level output. The microphone preamp is nearly always the first circuit to which a microphone output signal is subjected. Basically, a mic preamp prepares a microphone’s audio signal for use in all other audio devices.
```elixir

def pre_amplifier(%{signal_type: "mic"} = audio_signal, gain_amount) do
  amplify.(audio_signal, mic_to_line_level(gain_amount))
end
```
## **Equalizer**

&nbsp;&nbsp;&nbsp;&nbsp;Audio signals carry a dense amount of information and contain a combination of frequencies and amplitudes. Frequency refers to pitch (or how high or low something sounds) and is measured as time between sequential sound wave peaks. The quicker the time between peaks, the higher the pitch. But to complicate things, audio signals don’t just have one pitch, but a broad frequency profile across a spectrum which is usually measured from 20hz to 20,000hz (the estimated range of human hearing).

&nbsp;&nbsp;&nbsp;&nbsp;Each frequency in this entire range has an amplitude (or volume), which is the depth at which the frequency vibrates. Amplitude is measured as the difference in pressure between the peak and trough of a single wavelength. The larger the difference between peak and trough, the louder the sound.

&nbsp;&nbsp;&nbsp;&nbsp;So essentially, we have a long list of data index points [{:frequency, :gain}] to make up the frequency profile. Equalization is the manipulation of this frequency profile to make things sound more pleasing. For example, if a trumpet sounds too harsh or bright, an engineer might lower the gain of some of the higher frequencies to make a “softer” sound.

```elixir
def equalizer(%{frequency_profile: frequency_profile} = audio_signal, eq_changes) do
  Map.replace(audio_signal, frequency_profile, eq_changes)
end
```

## **Compression**

&nbsp;&nbsp;&nbsp;&nbsp;While equalization manipulates specific frequencies, compression manipulates average amplitude. It controls the dynamic range of amplitude, making sounds have a more consistent volume level. Compressors work by having a gain threshold level measured in decibels. If the input gain of the audio signal exceeds the threshold level, the gain which exceeds the threshold is reduced by a set ratio.

&nbsp;&nbsp;&nbsp;&nbsp;For example, if we have an input gain of 60dB, a threshold set to 50dB and a ratio set to 2:1, our output gain would be 55dB. This is because the 10dB difference between the input gain and threshold is reduced by half and allowed to pass with the remaining gain beneath the threshold.

&nbsp;&nbsp;&nbsp;&nbsp;Compressors typically also allow us to control the attack and release times that engage audio signals, as well as other fun things like side-chain compression (which does cool things like engage specific frequencies while ignoring others or feed an entirely separate audio signal to compress the volume of a different signal). But while outside the scope of explanation for this article, parallels to other programming concepts can be considered, such as conditional logic, pattern matching, asynchronous logic, etc.

```elixir
def compressor(%{gain: gain} = audio_signal, threshold, ratio) when gain > threshold do
  
  threshold_diff = gain - threshold
  compressed_diff = threshold_diff / ratio
  
  Map.replace(audio_signal, gain, threshold + compressed_diff)
end

```

## **Echo**

&nbsp;&nbsp;&nbsp;&nbsp;Echo is a fairly easy concept for most people to comprehend and is recursive in its programmatic implementation. We pass an audio signal, then after a given amount of time, feed the same quieter signal back to its input to repeat the process until the gain is reduced to 0dB.

&nbsp;&nbsp;&nbsp;&nbsp;Often times recording engineers send this as a parallel signal to an echo fx unit and feed the echoed signal back in further down the signal path. For the sake of brevity in this example, let’s assume that `echo()/3` is sending the echoed signal to a separate output while `send_to_echo()/3` is also passing the “dry” signal through the original path.

```elixir

def send_to_echo(audio_signal, delay_time, gain_offset, feedback) do
  echo(audio_signal, delay_time, gain_offset, feedback)
  audio_signal
end

def echo(%{gain: gain} = audio_signal, delay_time, gain_offset, feedback) when gain > 0 do
  # wet and dry are terms that refer respectively to affected and unaffected audio signals
  wet_audio_signal =
    Map.put(audio_signal, gain, gain - gain_offset + feedback)

  play_audio(wet_audio_signal)
  Process.sleep(delay_time)
  echo(wet_audio_signal, delay_time, feedback)

end
```

## **Recording Audio**

&nbsp;&nbsp;&nbsp;&nbsp;There are many different mediums for recording and not enough time to really dig in to the nuts and bolts of this concept. In short, analog signals can be recorded to mediums such as magnetic tape or directly to vinyl. They can also be converted to digital binary signals to be stored on a hard drive or further manipulated in digital audio workspaces (DAWs) like ProTools or Ableton Live. For this example, let’s just say we are converting the analog signal to digital so we can record to a DAW.

```elixir
def record_audio(audio_signal) do
  audio_signal
    |> convert_to_digital()
    |> save_to_drive()
end
```

## **Playback**

&nbsp;&nbsp;&nbsp;&nbsp;We can record audio all day, but if no one ever hears it, what’s the point? We need to play back these recorded audio signals by converting them from digital back to analog (if they are in a DAW). Then we need to amplify that analog signal through speakers, thus vibrating air molecules again to return an acoustic sound, which then travels into our ears and through a matrix of tissue, bones, hair, fluid, and nerves to create electrical impulses for our brains to interpret.

```elixir
def playback(%{signal: "digital"} = audio_signal, playback_volume) do
  audio_signal
    |> convert_to_analog()
    |> amplify()
    |> play_through_speakers(playback_volume)
end

def playback(%{signal: "analog"} = audio_signal, playback_volume) do
  audio_signal
    |> amplify()
    |> play_through_speakers(playback_volume)
  end
```

## **In Closing**

&nbsp;&nbsp;&nbsp;&nbsp;My point with all of this is not just that the concept of signal flow is ubiquitous, but more so that learning how to program can teach us to see the ubiquity of this repeated pattern. From a high-level perspective, this kind of analogous thought is helpful to understand basic or even intermediately complex concepts more quickly. Admittedly, as we dig deeper through the lower level logic of these types of comparisons, we inevitably find more discrepancy and dissonance in each analogy. However, I think this is what drives a lot of programmers. It is the pursuit to find and better understand the discrepancy and the dissonance so we can play with it, modify it, learn to solve problems with it, and ultimately transform ourselves to become better at both creating and fixing things in our surrounding world.
