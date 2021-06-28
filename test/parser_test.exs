defmodule Membrane.Element.RawVideo.ParserTest do
  use ExUnit.Case
  alias Membrane.Element.RawVideo.Parser
  alias Membrane.Buffer

  @framerate 30
  test "Process buffer with 3 frames" do
    assert {{:ok, actions}, state} =
             Parser.handle_process(:input, %Buffer{payload: "123456"}, nil, %{
               frame_size: 2,
               queue: <<>>,
               timestamp: 0,
               caps: %{
                 framerate: {0, 1}
               }
             })

    assert [buffer: {:output, bufs}] = actions

    assert bufs ==
             Enum.map(["12", "34", "56"], fn v -> %Buffer{payload: v, metadata: %{pts: 0}} end)
  end

  test "Process buffer with 2 and a half frames" do
    assert {{:ok, actions}, state} =
             Parser.handle_process(:input, %Buffer{payload: "12345"}, nil, %{
               frame_size: 2,
               queue: <<>>,
               timestamp: 0,
               caps: %{
                 framerate: {0, 1}
               }
             })

    assert [buffer: {:output, bufs}] = actions
    assert bufs == Enum.map(["12", "34"], fn v -> %Buffer{payload: v, metadata: %{pts: 0}} end)
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
    assert parser_state =
             Parser.handle_init(%Parser{format: :I420, width: 0, height: 0})
             |> elem(1)
             |> Map.put(:frame_size, 3)
             |> Map.put(:queue, "12")

    assert {{:ok, actions}, state} =
             Parser.handle_process(:input, %Buffer{payload: "345"}, nil, parser_state)

    assert [buffer: {:output, bufs}] = actions
    assert bufs == [%Buffer{payload: "123", metadata: %{pts: 0}}]
    assert state.queue == "45"
  end

  test "Parser add correct timestamps" do
    assert parser_state =
             Parser.handle_init(%Parser{
               format: :I420,
               width: 0,
               height: 0,
               framerate: {@framerate, 1}
             })
             |> elem(1)
             |> Map.put(:frame_size, 2)

    assert {{:ok, actions}, state} =
             Parser.handle_process(:input, %Buffer{payload: "123456"}, nil, parser_state)

    assert [buffer: {:output, bufs}] = actions

    assert bufs ==
             Enum.map(
               [
                 {"12", 0},
                 {"34", Ratio.new(Membrane.Time.second(), @framerate)},
                 {"56", Ratio.new(Membrane.Time.second() * 2, @framerate)}
               ],
               fn {v, pts} -> %Buffer{payload: v, metadata: %{pts: pts}} end
             )
  end
end
