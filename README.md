# Programmatic Parallels of Signal Flow

       Signal flow is something I find endlessly fascinating. In essence, the process of receiving an input, processing it, and returning its output is relatively easy to understand as a concept. But its implementation is such a ubiquitous process that you can look almost anywhere in the universe for examples of this. Breathing, cooking, war, photosynthesis, evolution, art, comedy, legislation, raising kids... all examples of the process of interacting with a set of given inputs and returning an outcome. 

       Since I started programming, I've been looking for ways to express other examples of this process through the lens of coding in an effort to better understand what it is I'm actually doing on a day-to-day basis. As a former recording studio engineer, I thought it would be fun to take a more programmatic look at audio signal flow and the environment in which it's created (the recording studio). My goal is to discuss parallels between the worlds of software development and the recording studio so that software devs and audio folks can better understand each others' process through their respective disciplines.  

       Before we dive into signal flow, it's important to talk a little about the environments in which they are created.

## The Software Studio as a Recording Studio

       Studios are places where we create things. Kinda obvious. Both in software studios and recording studios, there are different roles that each require different skill sets and responsibilities. Whether we’re in a software studio or recording studio, every team has a different chemistry and roles sometimes become interchangeable depending on that chemistry. Here's a breakdown of these roles and some of the ways they typically relate to each other:

## Product Owner as a Recording Artist

       A Product Owner in a sense is like a Recording Artist. They develop product features and goals, work with PMs to push the project further, and ultimately are responsible for the outcome of the project in the eyes of their company/investors.

       Recording Artists follow a similar path in the recording process. They are usually the creative force of the music (or most of it at least), they work with producers to keep the project moving forward, and ultimately they are responsible for the outcome of the recording, both in the eyes of their record label and their fans.

## Project Manager as a Producer

       A Project Manager is the liaison between software engineers and the PO, much like a producer is the liaison between recording engineer and the artist. PMs work with POs to develop features, set goals, and stay on task. They are responsible for knowing what is possible and understanding high level approaches to best achieve these goals. They then communicate these features, goals and approaches to the engineers, who implement them on a technical level. 

       Producers work almost exactly the same way. Depending on their relationships with the artist, record label and engineer, they have varying stakes in the creative process, but can communicate what is needed to achieve these creative goals. 
    
       Let's say the artist wants to replicate the sound of a 70s Italian soundtrack like *Suspiria*. The producer might work with the engineer to decide that they'll need to record directly to 2" tape through a certain console, with a certain plate reverb, tape echo, blah blah blah. It's then the engineer's responsibility to actually implement the sound that should be achieved by setting up the gear, calibrating the tape machine properly, choosing the exact signal path, etc.

## Engineer as ... well ... an engineer

        Both software engineers and recording engineers are the technical lynchpins of the entire project. They are responsible for technical troubleshooting, implementing the creative ideas of the PM/producer, file management and anything else that requires low level problem solving. It is also the responsibility of engineers to communicate any technical hurdles or potential blockers to the PM/producer that would inhibit the ultimate implementation of vision.

## Signal Flow

        Here's where we'll take a look at the path of a sound source (the input), its various manipulations through the recording process, and finally playback through speakers (the output) from a programmatic perspective using Elixir syntax. 
    
    *Disclaimer: this is mock code only used to demonstrate audio signal manipulation through Elixir syntax, therefore I'll be using functions that are clearly named, but not all explicitly documented.*

```elixir
defmodule SignalPath do
  import AudioSignal.{AudioSignal, AudioSignals}

    # in decibles
    @amount = 40,
    # some map of tuples {:frequency, :gain}
    @eq_changes = {{60, 2}, {315, -4}, {2500, -2}, {12_000, 1}},
    # in decibles
    @threshold = 35,
    # numerator
    @ratio = 3,
    # in milliseconds
    @delay_time = 225,
    # in decibles
    @feedback = 5

  def create_signal_path(%AudioSignal{} = audio_signal) do
    audio_signal
    |> microphone()
    |> pre_amplifier(@amount)
    |> equaliser(@eq_changes)
    |> compressor(@threshold, @ratio)
    |> send_to_echo(@delay_time, @feedback)
    |> record_audio()
    |> playback()
  end
end
```

## The Sound Source

       Before sound is recorded, it must be created. All sounds are essentially vibrations of air molecules at specific frequencies and amplitudes. That's how sound is created and also how we perceive it (unless we're actually *looking* at sonographic data). Let's start with the example of a vocalist singing a melody. The simple explanation is that a vocalist pushes air from the lungs past the vocal cords, which vibrate more air molecules to manipulate pitch and volume.

       Below is a very basic schema for an audio signal and sound wave.

```elixir
defmodule AudioSignal do
  @type t :: %__MODULE__{
          signal_type: String.t(),
          gain: integer(),
          # %Wave{}
          frequency_profile: Wave.t()
        }

  defstruct [
    :signal_type,
    :gain,
    :frequency_profile
  ]
end
```

```
defmodule Wave do
  @type t :: %__MODULE__{
          frequency: integer(),
          gain: integer()
        }
  defstruct [{:frequency, :gain}]
end
```

     

## Microphone

       Microphones take acoustic sounds and convert them to analog electrical audio signals. They do this by using elements such as diaphragms, condensers, or metallic ribbons, which reverberate from an incoming sound source (like the sound of our vocalist) and use electromagnetism to convert that air pressure into an analog electrical signal. The amplification level is now the measure of voltage of this signal. It's called gain, which can be thought of as the electrical expression of volume.

```elixir
def microphone(%AudioSignal{signal_type: "acoustic"} = audio_signal) do
    convert_to_analog(audio_signal)

    Map.put(
      audio_signal,
      :signal,
      "mic"
    )
  end
```

## Pre-amplifier

       A mic preamplifier (or preamp) is an amplifying circuit designed to boost a mic level input to a line level output. The microphone preamp is nearly always the first circuit to which a microphone output signal is subjected. Basically, a mic preamp prepares a microphone's audio signal for use in all other audio devices.

```elixir
def pre_amplifier(%{signal_type: "mic"} = audio_signal, amount) do
    amplify.(audio_signal, mic_to_line_level(amount))
  end
```

## Equalizer

       Audio signals carry a dense amount of information. They are a combination of frequencies and amplitudes. Frequency refers to pitch (or how high or low something sounds). To complicate things, audio signals don't just have one pitch, but a broad frequency profile across a spectrum which is usually measured from 20hz to 20,000hz (the estimated range of human hearing). 

       Each frequency in this entire range has an amplitude (or the volume), which is the depth at which the frequency vibrates. So essentially, we have a long list of data index points [{:frequency, :gain}] to make up the frequency profile. 

       Equalization is the manipulation of this frequency profile to make things sound more pleasing. For example, if a trumpet sounds too harsh or bright, an engineer might lower the gain of some of the higher frequencies to make a "softer" sound.

```elixir
def equaliser(audio_signal, eq_changes) do
    Map.put(
      audio_signal,
      :frequency_profile,
      eq_changes
    )
  end
```

## Compression

       While equalization manipulates frequency (the time between recurring wavelength peaks, aka pitch), compression deals with the amplitude (the difference between a wavelength's peak and trough, aka volume). Compression controls the dynamic range of amplitude, making sounds have a more consistent volume level. 

       Compressors work by having a gain threshold level measured in decibels. If the input gain of the audio signal exceeds the threshold level, the gain which exceeds the threshold is reduced by a set ratio. 

       For example, if we have an input gain of 60dB, a threshold set to 50dB and a ratio set to 2:1, our output gain would be 55dB. This is because the 10dB difference between the input gain and threshold is reduced by half and allowed to pass with the remaining gain beneath the threshold. 

       Compressors typically also allow us to control the attack and release times that engage audio signals, as well as other fun things like side-chain compression (which does cool things like engage specific frequencies while ignoring others or feed an entirely separate audio signal to compress the volume of a different signal). But while outside the scope of explanation for this article, parallels to other programming concepts can be considered, such as conditional logic, pattern matching, asynchronous logic, etc.

```elixir
def compressor(audio_signal, threshold, ratio) 
	when :gain > threshold do
    threshold_diff = :gain - threshold
    compressed_diff = threshold_diff / ratio

    Map.put(
      audio_signal,
      :gain,
      threshold + compressed_diff
    )
  end
```

## Echo

       Echo is a fairly easy concept for most people to comprehend and is recursive in its programmatic implementation. We pass an audio signal, then after a given amount of time, feed the same quieter signal back to its input to repeat the process until the gain is reduced to 0dB. 

       Often times recording engineers send this as a parallel signal to an echo fx unit and feed the echoed signal back in further down the signal path. For the sake of brevity in this example, let's assume that echo()/3 is sending the echoed signal to a separate output while send_to_echo()/3 is also passing the "dry" signal through the original path.

```elixir
def send_to_echo(audio_signal, delay_time, feedback) do
    echo(audio_signal, delay_time, feedback)
    audio_signal
  end

def echo(audio_signal, delay_time, feedback) when :gain > 0 do
  wet_audio_signal =
    Map.put(
      audio_signal,
      :gain,
      :gain - 10 + feedback
    )

  play_audio(wet_audio_signal)
  Process.sleep(delay_time)
  echo(wet_audio_signal, delay_time, feedback)
end
```

## Recording Audio

       There are many different mediums for recording and not enough time to really dig in to the nuts and bolts of this concept. In short, analog signals can be recorded to mediums such as magnetic tape or vinyl. They can also be converted to digital binary signals to be stored on a hard drive or further manipulated in a digital audio workspace (DAW) like ProTools or Ableton Live.

       For this example, let's just say we are converting the analog signal to digital so we can record to a DAW.

```elixir
def record_audio(audio_signal) do
    audio_signal
    |> convert_to_digital()
    |> save_to_drive()
  end
```

## Playback

       We can record audio all day, but if no one ever hears it, what's the point? We need to play back these recorded audio signals by converting them from digital back to analog (if they are in a DAW). Then we need to amplify that analog signal through speakers, thus vibrating air molecules again to return an acoustic sound, which then travels into our ears and through a matrix of tissue, bones, hair, fluid, and nerves to create electrical impulses for our brains to interpret.

```elixir
def playback(%{signal: "digital"} = audio_signal) do
    audio_signal
    |> convert_to_analog()
    |> amplify()
    |> play_through_speakers()
  end

  def playback(%{signal: "analog"} = audio_signal) do
    audio_signal
    |> amplify()
    |> play_through_speakers()
  end
```

## In Closing

       There are a lot of other parallels to find between programming and recording if we want to dig deeper. One that comes to mind is the pipe operator in Elixir. It is essentially like a normalized patch bay, connecting inputs and outputs without having to explicitly pass its return value as the next argument. Similarly when patch bays are normalized, we don't even have to use patch cables if the channels are thoughtfully laid out. 

       My point with all of this is not just that the simple concept of signal flow is ubiquitous in the world, but more so that learning how to program can teach us to see this repeated pattern in its ubiquity. From a high level perspective, this kind of analogous thought is helpful to understand basic or even intermediately complex concepts more quickly. But admittedly, as we dig deeper through the lower level logic of these types of comparisons, we often inevitably find more discrepancy and dissonance in our analogies. I think this is kind of a driver for a lot of programmers, though. It is the pursuit to find and better understand the discrepancy and the dissonance, so we can play with it, modify it, learn to solve problems with it, and in the end transform ourselves to become better at both creating and fixing things in our surrounding world.