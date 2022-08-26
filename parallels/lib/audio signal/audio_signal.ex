defmodule AudioSignal do
  @type t :: %__MODULE__{
          signal: String.t(),
          gain: integer(),
          # %Wave{}
          frequency_profile: Wave.t()
        }

  defstruct [
    :signal,
    :gain,
    :frequency_profile
  ]
end
