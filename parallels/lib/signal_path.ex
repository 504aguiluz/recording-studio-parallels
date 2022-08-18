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
    |> capture_audio()
  end
end
