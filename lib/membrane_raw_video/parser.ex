defmodule Membrane.RawVideo.Parser do
  @moduledoc """
  Simple module responsible for splitting the incoming buffers into
  frames of raw (uncompressed) video frames of desired format.

  The parser sends proper caps when moves to playing state.
  No data analysis is done, this element simply ensures that
  the resulting packets have proper size.
  """
  use Membrane.Filter
  alias Membrane.{Buffer, Payload}
  alias Membrane.RawVideo

  def_input_pad :input, demand_unit: :bytes, demand_mode: :auto, caps: :any

  def_output_pad :output, demand_mode: :auto, caps: {RawVideo, aligned: true}

  def_options pixel_format: [
                type: :atom,
                spec: RawVideo.pixel_format_t(),
                description: """
                Format used to encode pixels of the video frame.
                """
              ],
              width: [
                type: :int,
                description: """
                Width of a frame in pixels.
                """
              ],
              height: [
                type: :int,
                description: """
                Height of a frame in pixels.
                """
              ],
              framerate: [
                type: :tuple,
                spec: Raw.framerate_t(),
                default: {0, 1},
                description: """
                Framerate of video stream. Passed forward in caps.
                """
              ]

  @supported_formats [:I420, :I422, :I444, :RGB, :BGRA, :RGBA, :NV12, :NV21, :YV12, :AYUV]

  @impl true
  def handle_init(opts) do
    unless opts.format in @supported_formats do
      raise """
      Unsupported frame format: #{inspect(opts.format)}
      The elements supports: #{Enum.map_join(@supported_formats, ", ", &inspect/1)}
      """
    end

    frame_size =
      case RawVideo.frame_size(opts.pixel_format, opts.width, opts.height) do
        {:ok, frame_size} ->
          frame_size

        {:error, :invalid_dims} ->
          raise "Provided dimensions (#{opts.width}x#{opts.height}) are invalid for #{inspect(opts.pixel_format)} pixel format"
      end

    caps = %RawVideo{
      format: opts.pixel_format,
      width: opts.width,
      height: opts.height,
      framerate: opts.framerate,
      aligned: true
    }

    {num, denom} = caps.framerate
    frame_duration = if num == 0, do: 0, else: Ratio.new(denom * Membrane.Time.second(), num)

    {:ok,
     %{
       caps: caps,
       timestamp: 0,
       frame_duration: frame_duration,
       frame_size: frame_size,
       queue: []
     }}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    {{:ok, caps: {:output, state.caps}}, state}
  end

  @impl true
  def handle_caps(:input, caps, _ctx, state) do
    # Do not forward caps
    {num, denom} = caps.framerate
    frame_duration = if num == 0, do: 0, else: Ratio.new(denom * Membrane.Time.second(), num)

    {:ok, %{state | frame_duration: frame_duration}}
  end

  @impl true
  def handle_process_list(:input, buffers, _ctx, state) do
    %{frame_size: frame_size} = state

    payload_iodata =
      buffers |> Enum.map(fn %Buffer{payload: payload} -> Payload.to_binary(payload) end)

    queue = [payload_iodata | state.queue]
    size = IO.iodata_length(queue)

    if size < frame_size do
      {:ok, %{state | queue: queue}}
    else
      data_binary = queue |> Enum.reverse() |> IO.iodata_to_binary()

      {payloads, tail} = Bunch.Binary.chunk_every_rem(data_binary, frame_size)

      {bufs, state} =
        payloads
        |> Enum.map_reduce(state, fn payload, state_acc ->
          timestamp = state_acc.timestamp |> Ratio.floor()
          {%Buffer{payload: payload, pts: timestamp}, bump_timestamp(state_acc)}
        end)

      {{:ok, buffer: {:output, bufs}}, %{state | queue: [tail]}}
    end
  end

  @impl true
  def handle_prepared_to_stopped(_ctx, state) do
    {:ok, %{state | queue: []}}
  end

  defp bump_timestamp(%{caps: %{framerate: {0, _}}} = state) do
    state
  end

  defp bump_timestamp(state) do
    use Ratio
    %{timestamp: timestamp, frame_duration: frame_duration} = state
    timestamp = timestamp + frame_duration
    %{state | timestamp: timestamp}
  end
end
