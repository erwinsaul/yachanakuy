defmodule CSV do
  @moduledoc """
  CSV parser module using NimbleCSV
  """

  NimbleCSV.define(Parser, separator: ",", escape: "\"")

  def decode(stream, options \\ []) do
    headers = Keyword.get(options, :headers, false)

    if headers do
      decode_with_headers(stream)
    else
      Parser.parse_stream(stream)
    end
  end

  defp decode_with_headers(stream) do
    stream
    |> Stream.transform(nil, fn
      row, nil ->
        # First row is headers
        {[], row}

      row, headers ->
        # Subsequent rows become maps
        map = Enum.zip(headers, row) |> Map.new()
        {[{:ok, map}], headers}
    end)
  end
end
