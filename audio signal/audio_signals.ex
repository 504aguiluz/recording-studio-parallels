defmodule AudioSignals do
  def microphone(
    %AudioSignal{amplification_level: "none"} = audio_signal) do
    convert_to_analog(audio_signal)
    Map.put(
      audio_signal,
      :amplification_level,
      "mic"
    )
  end

  def pre_amplifier(%{amplification_level: "mic"} = audio_signal, amount) do
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
      threshold_diff = audio_signal.gain - threshold
      compressed_diff = threshold_diff / ratio

        Map.put(
          audio_signal,
          :gain,
          threshold + compressed_diff
          )
    end
  end

  def send_to_echo(audio_signal, delay_time, feedback) do
    echo(audio_signal, delay_time, feedback)
    {:noreply, audio_signal}
  end

  def echo(%{gain: gain} = audio_signal, delay_time, feedback) when audio_signal.gain > 0 do
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

  def amplify(%{gain: gain} = audio_signal, amount) do
    audio_signal =
      Map.put(
        audio_signal,
        :gain,
        :gain + amount
      )
  end

  def capture_audio(audio_signal) do
    audio_signal
    |> convert_to_digital()
    |> record_audio_signal()

  end
end
