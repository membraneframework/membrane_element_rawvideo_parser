defmodule Membrane.RawVideo.ParserPipelineTest do
  use ExUnit.Case, async: true

  import Membrane.ParentSpec
  import Membrane.Testing.Assertions

  alias Membrane.RawVideo.Parser
  alias Membrane.{Buffer, Testing}

  @width 80
  @height 60
  @rgb_bpp 3 * 8
  @frame_bits @width * @height * @rgb_bpp
  @fps 24

  defp pipeline_test(chunk_size, dir) do
    num_frames = 30
    size = num_frames * @frame_bits
    black_frames = <<0::size(size)>>
    fixture_path = Path.join(dir, "in_black.rgb")
    File.write!(fixture_path, black_frames)
    on_exit(fn -> File.rm!(fixture_path) end)

    pipeline_opts = %Testing.Pipeline.Options{
      elements: [
        file_src: %Membrane.File.Source{location: fixture_path},
        parser: %Parser{
          pixel_format: :RGB,
          width: @width,
          height: @height,
          framerate: {@fps, 1}
        },
        sink: Testing.Sink
      ],
      links: [
        link(:file_src)
        |> via_in(:input, auto_demand_size: chunk_size)
        |> to(:parser)
        |> to(:sink)
      ]
    }

    assert {:ok, pipeline} = Testing.Pipeline.start_link(pipeline_opts)

    assert_start_of_stream(pipeline, :sink)

    for i <- 0..(num_frames - 1) do
      assert_sink_buffer(pipeline, :sink, %Buffer{pts: pts, payload: payload})
      assert bit_size(payload) == @frame_bits
      assert pts == i |> Ratio.*(Ratio.new(Membrane.Time.second(), @fps)) |> Ratio.floor()
    end

    assert_end_of_stream(pipeline, :sink)
    Testing.Pipeline.terminate(pipeline, blocking?: true)
  end

  @moduletag :tmp_dir

  test "with small chunks from source", %{tmp_dir: dir} do
    pipeline_test(10, dir)
  end

  test "with huge chunks from source", %{tmp_dir: dir} do
    pipeline_test(440_000, dir)
  end
end
