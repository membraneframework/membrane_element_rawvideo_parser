defmodule Membrane.Element.RawVideo.Parser do
  use Membrane.Element.Base.Filter
  alias Membrane.{Buffer, Payload}
  alias Membrane.Caps.Video.Raw
  alias Membrane.Element.RawVideo.ParserHelper

  def_input_pads input: [
                   demand_unit: :bytes,
                   caps: :any
                 ]

  def_output_pads output: [
                    caps: {Raw, aligned: true}
                  ]

  def_options format: [
                type: :atom,
                spec: Raw.format_t(),
                description: """
                Format used to encode pixels of the video frame.
                """
              ],
              width: [
                type: :int,
                description: """
                Width of a frame in pixels
                """
              ],
              height: [
                type: :int,
                description: """
                Height of a frame in pixels
                """
              ],
              framerate: [
                type: :tuple,
                spec: Raw.framerate_t(),
                default: {0, 1},
                description: """
                Framerate of video stream. Passed down in cap.
                """
              ]

  @impl true
  def handle_init(opts) do
    with {:ok, frame_size} <- ParserHelper.get_frame_size(opts.format, opts.width, opts.height) do
      {:ok, %{frame_size: frame_size, queue: <<>>}}
    end
  end

  @impl true
  def handle_demand(:input, bufs, :buffers, _, state) do
    {{:ok, demand: {:input, bufs * state.frame_size}}, state}
  end

  def handle_demand(:input, size, :bytes, _, state) do
    {{:ok, demand: {:input, size}}, state}
  end

  @impl true
  def handle_caps(:input, _caps, _ctx, state) do
    # Do not forward caps
    {:ok, state}
  end

  @impl true
  def handle_process(:input, %Buffer{payload: raw_payload}, _ctx, state) do
    %{frame_size: frame_size} = state
    payload = state.queue <> Payload.to_binary(raw_payload)
    size = byte_size(payload)

    if size < frame_size do
      {:ok, %{state | queue: payload}}
    else
      {bufs, tail} = split_into_buffers(payload, frame_size)
      {{:ok, buffer: {:output, bufs}}, %{state | queue: tail}}
    end
  end

  @impl true
  def handle_prepared_to_stopped(_, state) do
    {:ok, %{state | queue: <<>>}}
  end

  defp split_into_buffers(data, frame_size, acc \\ [])

  defp split_into_buffers(data, frame_size, acc) when byte_size(data) < frame_size do
    {acc |> Enum.reverse(), data}
  end

  defp split_into_buffers(data, frame_size, acc) do
    <<frame::bytes-size(frame_size), tail::binary>> = data
    split_into_buffers(tail, frame_size, [%Buffer{payload: frame} | acc])
  end
end
