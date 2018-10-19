defmodule Membrane.Element.RawVideo.ParserTest do
  use ExUnit.Case
  alias Membrane.Element.RawVideo.Parser
  alias Membrane.Buffer

  test "" do
    assert {{:ok, actions}, state} =
             Parser.handle_process(:input, %Buffer{payload: "123456"}, nil, %{
               frame_size: 2,
               queue: <<>>
             })

    assert [buffer: {:output, bufs}] = actions
    assert bufs == Enum.map(["12", "34", "56"], fn v -> %Buffer{payload: v} end)
  end
end
