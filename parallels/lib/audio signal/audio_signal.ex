defmodule Wave do
  @type t :: %__MODULE__{
          frequency: integer(),
          gain: integer()
        }
  defstruct [:frequency, :gain]
end

defmodule AudioSignal do
  @type :: %__MODULE__{
    amplification_level: string(),
    gain: integer(),
    mix_gain: integer(),
    max_gain: integer(),
    # %Wave{}
    frequency_profile: Wave.t()
  }

  defstruct

  [
    amplification_level: "none",
    gain: 0,
    min_gain: 0,
    max_gain: 0,
    frequency_profile: [Wave.t()]
  ]
end
