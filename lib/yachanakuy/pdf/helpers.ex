defmodule Yachanakuy.Pdf.Helpers do
  @moduledoc """
  Módulo de ayuda para funciones comunes en la generación de PDFs.
  """

  @doc """
  Formatea una fecha para mostrar en los PDFs.
  """
  def format_date(nil), do: ""
  
  def format_date(%Date{} = date) do
    "#{date.day}/#{date.month}/#{date.year}"
  end
  
  def format_date(%DateTime{} = datetime) do
    "#{datetime.day}/#{datetime.month}/#{datetime.year}"
  end
  
  def format_date(date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed_date} -> format_date(parsed_date)
      {:error, _} -> date
    end
  end

  @doc """
  Formatea porcentaje con dos decimales.
  """
  def format_percentage(nil), do: "0.00%"
  
  def format_percentage(percentage) when is_number(percentage) do
    "#{:erlang.float_to_binary(Float.round(percentage, 2), decimals: 2)}%"
  end
  
  def format_percentage(percentage) when is_binary(percentage) do
    case Float.parse(percentage) do
      {num, _} -> format_percentage(num)
      :error -> "0.00%"
    end
  end

  @doc """
  Asegura que una URL sea segura para incluir en HTML/PDF.
  """
  def safe_url(nil), do: ""
  def safe_url(url) when is_binary(url) and url != "", do: url
  def safe_url(_), do: ""
end