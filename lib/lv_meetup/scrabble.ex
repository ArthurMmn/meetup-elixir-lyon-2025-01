defmodule LvMeetup.Scrabble do
  @moduledoc """
  A module for managing and retrieving Scrabble words from a file.
  """

  use Agent

  @file_path "ods.txt"

  def start_link(_) do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  def all do
    Agent.get_and_update(__MODULE__, fn
      nil ->
        case File.read(@file_path) do
          {:ok, content} ->
            words = String.split(content, "\n", trim: true)
            {words, words}

          {:error, reason} ->
            {:error, reason}
        end

      words ->
        {words, words}
    end)
  end

  def result(word) do
    word = clean(word)

    if valid?(word) do
      [status: :ok, word: word, score: score(word)]
    else
      [status: :error, word: word]
    end
  end

  def valid?(word) do
    word in all()
  end

  def score(word) do
    word
    |> String.graphemes()
    |> Enum.map(&score_letter/1)
    |> Enum.sum()
  end

  def search(str, limit \\ 50) do
    str = clean(str)

    __MODULE__.all()
    |> Stream.filter(&String.starts_with?(&1, str))
    |> Stream.take(limit)
    |> Enum.to_list()
  end

  defp score_letter("A"), do: 1
  defp score_letter("E"), do: 1
  defp score_letter("I"), do: 1
  defp score_letter("L"), do: 1
  defp score_letter("N"), do: 1
  defp score_letter("O"), do: 1
  defp score_letter("R"), do: 1
  defp score_letter("S"), do: 1
  defp score_letter("T"), do: 1
  defp score_letter("U"), do: 1

  defp score_letter("D"), do: 2
  defp score_letter("G"), do: 2
  defp score_letter("M"), do: 2

  defp score_letter("B"), do: 3
  defp score_letter("C"), do: 3
  defp score_letter("P"), do: 3

  defp score_letter("F"), do: 4
  defp score_letter("H"), do: 4
  defp score_letter("V"), do: 4

  defp score_letter("J"), do: 8
  defp score_letter("Q"), do: 8

  defp score_letter("K"), do: 10
  defp score_letter("W"), do: 10
  defp score_letter("X"), do: 10
  defp score_letter("Y"), do: 10
  defp score_letter("Z"), do: 10

  defp score_letter(_), do: 0

  def clean(str) do
    str
    |> String.normalize(:nfd)
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.upcase()
  end
end
