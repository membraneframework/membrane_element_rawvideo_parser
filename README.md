# Membrane raw video parser plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_raw_video_parser_plugin.svg)](https://hex.pm/packages/membrane_raw_video_parser_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_raw_video_parser_plugin/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_raw_video_parser_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_raw_video_parser_plugin)

This package provides an element parsing a data stream into raw (uncompressed) video frames.
Documentation is available at [HexDocs](https://hexdocs.pm/membrane_raw_video_parser_plugin/)

It is part of [Membrane Multimedia Framework](https://membrane.stream/).

## Installation

Add the following line to your `deps` in `mix.exs`. Run `mix deps.get`.

```elixir
	{:membrane_raw_video_parser_plugin, "~> 0.8.0"}
```
## Usage
The pipeline below displays a sample raw video from file using Membrane raw video parser plugin and 
Membrane SDL plugin.

```elixir
defmodule Membrane.RawVideo.Parser.Pipeline do

  use Membrane.Pipeline

  @doc """
  handle_init(%{
    video_path: String.t(),
    caps: Membrane.RawVideo
  })
  """
  @impl true
  def handle_init(options) do
    parser = %Membrane.RawVideo.Parser{
      framerate: options.caps.framerate,
      width: options.caps.width,
      height: options.caps.height,
      pixel_format: options.caps.pixel_format
    }

    children = %{
      file_src: %Membrane.File.Source{location: options.video_path},
      parser: parser,
      sdl: Membrane.SDL.Player
    }

    links = [
      link(:file_src)
      |> to(:parser)
      |> to(:sdl)
    ]

    {{:ok, spec: %ParentSpec{children: children, links: links}, playback: :playing}, %{}}
  end

  @impl true
  def handle_element_end_of_stream({:sdl, _}, _context, state) do
    {{:ok, [playback: :terminating]}, state}
  end

  @impl true
  def handle_element_end_of_stream({_pad, _src}, _context, state) do
    {:ok, state}
  end
end
```



## Copyright and License

Copyright 2018, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
