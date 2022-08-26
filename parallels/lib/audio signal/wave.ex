defmodule Wave do
  @type t :: %__MODULE__{
          frequency: integer(),
          gain: integer()
        }
  defstruct [:frequency, :gain]
end
