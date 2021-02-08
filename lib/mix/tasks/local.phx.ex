defmodule Mix.Tasks.Local.Petal do
  use Mix.Task

  @shortdoc "Updates the Phoenix project generator locally"

  @moduledoc """
  Updates the Phoenix project generator locally.

      mix local.petal

  Accepts the same command line options as `archive.install hex petal_new`.
  """

  @impl true
  def run(args) do
    Mix.Task.run("archive.install", ["hex", "petal_new" | args])
  end
end
