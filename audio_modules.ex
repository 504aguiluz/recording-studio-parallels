defmodule AudioModules do
  def microphone(%AudioSignal{amplification_level: "none"} = audio_signal) do
    convert_to_analog(audio_signal)

    {:ok, audio_signal}
  end

  def pre_amplifier(%{amplification_level: "mic"} = audio_signal, amount) do
    amplify.(audio_signal, mic_to_line_level(amount))

    {:ok, audio_signal}
  end

  def equaliser(audio_signal, eq_changes) do
    audio_signal =
      Map.put(
        audio_signal,
        audio_signal.frequency_profile,
        eq_changes
      )

    {:ok, audio_signal}
  end

  def compressor(audio_signal, threshold, ratio) do
    case audio_signal.gain > threshold do
      threshold_diff = audio_signal.gain - threshold
      compressed_diff = threshold_diff / ratio
      audio_signal = Map.put(audio_signal, audio_signal.gain, threshold + compressed_diff)

      {:ok, audio_signal}
    end
  end

  def echo(audio_signal, delay_time, feedback, echo_amount \\ 0) when audio_signal.gain > 0 do
    wet_audio_signal =
      Map.put(
        audio_signal,
        audio_signal.gain,
        audio_signal.gain - 10 + feedback
      )

    case echo_amount = 0 do
      play_audio(audio_signal)
      Process.sleep(delay_time)
      echo(wet_audio_signal, delay_time, feedback, echo_amount + 1)
      {:ok, audio_signal}
    end

    case echo_amount > 0 do
      play_audio(wet_audio_signal)
      Process.sleep(delay_time)
      echo(wet_audio_signal, delay_time, feedback, echo_amount)
      {:ok, audio_signal}
    end
  end

  def amplify(audio_signal, amount) do
    audio_signal =
      Map.put(
        audio_signal,
        audio_signal.gain,
        audio_signal.gain + amount
      )

    {:ok, audio_signal}
  end
end
