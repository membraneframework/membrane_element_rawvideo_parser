defmodule Membrane.Element.RawVideo.ParserTest do
  use ExUnit.Case
  alias Membrane.Element.RawVideo.Parser
  alias Membrane.Buffer

  test "Process buffer with 3 frames" do
    assert {{:ok, actions}, state} =
             Parser.handle_process(:input, %Buffer{payload: "123456"}, nil, %{
               frame_size: 2,
               queue: <<>>
             })

    assert [buffer: {:output, bufs}] = actions
    assert bufs == Enum.map(["12", "34", "56"], fn v -> %Buffer{payload: v} end)
  end

  test "Process buffer with 2 and a half frames" do
    assert {{:ok, actions}, state} =
             Parser.handle_process(:input, %Buffer{payload: "12345"}, nil, %{
               frame_size: 2,
               queue: <<>>
             })

    assert [buffer: {:output, bufs}] = actions
    assert bufs == Enum.map(["12", "34"], fn v -> %Buffer{payload: v} end)
    assert state.queue == "5"
  end

  test "Process buffer without full frame" do
    assert {:ok, state} =
             Parser.handle_process(:input, %Buffer{payload: "12345"}, nil, %{
               frame_size: 6,
               queue: <<>>
             })

    assert state.queue == "12345"
  end

  test "Process buffer with part of frame queued" do
    assert {{:ok, actions}, state} =
             Parser.handle_process(:input, %Buffer{payload: "345"}, nil, %{
               frame_size: 3,
               queue: "12"
             })

    assert [buffer: {:output, bufs}] = actions
    assert bufs == [%Buffer{payload: "123"}]
    assert state.queue == "45"
  end
end
