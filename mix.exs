for path <- :code.get_path,
    Regex.match?(~r/petal_new\-\d+\.\d+\.\d\/ebin$/, List.to_string(path)) do
  Code.delete_path(path)
end

defmodule Petal.New.MixProject do
  use Mix.Project

  @version "0.0.1"
  @url "https://github.com/shankardevy/petal_new"

  def project do
    [
      app: :petal_new,
      start_permanent: Mix.env() == :prod,
      version: @version,
      elixir: "~> 1.11",
      deps: deps(),
      package: [
        maintainers: [
          "Shankar Dhanasekaran",
        ],
        licenses: ["MIT"],
        links: %{github: @url},
        files: ~w(lib templates mix.exs README.md)
      ],
      source_url: @url,
      homepage_url: "https://www.phoenixframework.org",
      description: """
      PETAL Stack project generator.

      Provides a `mix petal.new` task to bootstrap a new Elixir application
      with Phoenix, Tailwind, Alpinejs and Liveview dependencies.
      """
    ]
  end

  def application do
    [
      extra_applications: [:eex, :crypto]
    ]
  end

  def deps do
    [
      {:ex_doc, "~> 0.23", only: :dev}
    ]
  end
end
