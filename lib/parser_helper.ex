defmodule Membrane.Element.RawVideo.ParserHelper do
  alias Membrane.Caps.Video.Raw
  require Integer

  @spec get_frame_size(Raw.format_t(), Raw.width_t(), Raw.height()) ::
          Bunch.Type.try_t(pos_integer)
  def get_frame_size(format, width, height)
      when format in [:I420, :YV12, :NV12, :NV21] and Integer.is_even(width) and
             Integer.is_even(height) do
    # Subsampling by 2 in both dimensions
    # Y = width * height
    # V = U = (width / 2) * (height / 2)
    {:ok, width * height / 2 * 3}
  end

  def get_frame_size(:I422, width, height) when Integer.is_even(width) do
    # Subsampling by 2 in horizontal dimension
    # Y = width * height
    # V = U = (width / 2) * height
    {:ok, width * height * 3}
  end

  def get_frame_size(format, width, height) when format in [:I444, :RGB] do
    # No subsampling
    {:ok, width * height * 3}
  end

  def get_frame_size(format, width, height) when format in [:AYUV, :RGBA, :BGRA] do
    # No subsampling and added alpha channel
    {:ok, width * height * 4}
  end

  def get_frame_size(_, _, _) do
    {:error, :invalid_dims}
  end
end
