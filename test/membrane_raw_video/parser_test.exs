defmodule Membrane.RawVideo.ParserTest do
  use ExUnit.Case, async: true
  alias Membrane.RawVideo.Parser
  alias Membrane.Buffer

  @framerate 30
  test "Process buffer with 3 frames" do
    assert {{:ok, actions}, _state} =
             Parser.handle_process_list(:input, [%Buffer{payload: "123456"}], nil, %{
               frame_size: 2,
               queue: [],
               timestamp: 0,
               caps: %{
                 framerate: {0, 1}
               }
             })

    assert [buffer: {:output, bufs}] = actions

    assert bufs ==
             Enum.map(["12", "34", "56"], fn v -> %Buffer{payload: v, pts: 0} end)
  end

  test "Process buffer with 2 and a half frames" do
    assert {{:ok, actions}, state} =
             Parser.handle_process_list(:input, [%Buffer{payload: "12345"}], nil, %{
               frame_size: 2,
               queue: [],
               timestamp: 0,
               caps: %{
                 framerate: {0, 1}
               }
             })

    assert [buffer: {:output, bufs}] = actions
    assert bufs == Enum.map(["12", "34"], fn v -> %Buffer{payload: v, pts: 0} end)
    assert IO.iodata_to_binary(state.queue) == "5"
  end

  test "Process buffer without full frame" do
    assert {:ok, state} =
             Parser.handle_process_list(:input, [%Buffer{payload: "12345"}], nil, %{
               frame_size: 6,
               queue: []
             })

    assert IO.iodata_to_binary(state.queue) == "12345"
  end

  test "Process buffer with part of frame queued" do
    assert parser_state =
             Parser.handle_init(%Parser{format: :I420, width: 0, height: 0})
             |> elem(1)
             |> Map.put(:frame_size, 3)
             |> Map.put(:queue, ["12"])

    assert {{:ok, actions}, state} =
             Parser.handle_process_list(:input, [%Buffer{payload: "345"}], nil, parser_state)

    assert [buffer: {:output, bufs}] = actions
    assert bufs == [%Buffer{payload: "123", pts: 0}]
    assert IO.iodata_to_binary(state.queue) == "45"
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

    assert {{:ok, actions}, _state} =
             Parser.handle_process_list(:input, [%Buffer{payload: "123456"}], nil, parser_state)

    assert [buffer: {:output, bufs}] = actions

    assert bufs ==
             Enum.map(
               [
                 {"12", 0},
                 {"34", Ratio.new(Membrane.Time.second(), @framerate) |> Ratio.floor()},
                 {"56", Ratio.new(Membrane.Time.second() * 2, @framerate) |> Ratio.floor()}
               ],
               fn {v, pts} -> %Buffer{payload: v, pts: pts} end
             )
  end
end
