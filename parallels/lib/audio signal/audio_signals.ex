defmodule AudioSignals do
  # alias AudioSignal.AudioSignal

  def microphone(%AudioSignal{signal: "acoustic"} = audio_signal) do
    convert_to_analog(audio_signal)

    Map.put(
      audio_signal,
      :signal,
      "mic"
    )
  end

  def amplify(audio_signal, amount) do
    Map.put(
      audio_signal,
      :gain,
      :gain + amount
    )
  end

  def pre_amplifier(%{signal: "mic"} = audio_signal, amount) do
    amplify.(audio_signal, mic_to_line_level(amount))
  end

  def equaliser(audio_signal, eq_changes) do
    Map.put(
      audio_signal,
      :frequency_profile,
      eq_changes
    )
  end

  def compressor(%{gain: gain} = audio_signal, threshold, ratio) when gain > threshold do
    threshold_diff = :gain - threshold
    compressed_diff = threshold_diff / ratio

    Map.put(
      audio_signal,
      :gain,
      threshold + compressed_diff
    )
  end

  def send_to_echo(audio_signal, delay_time, feedback) do
    echo(audio_signal, delay_time, feedback)
    audio_signal
  end

  def echo(%{gain: _gain} = audio_signal, delay_time, feedback) when :gain > 0 do
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

  def record_audio(audio_signal) do
    audio_signal
    |> convert_to_digital()
    |> save_to_drive()
  end

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
end
