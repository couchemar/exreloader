defmodule Exreloader.Mixfile do
  use Mix.Project

  def project do
    [ app: :exreloader,
      version: "0.0.2",
      deps: deps,
      elixir: "~> 0.12.4" ]
  end

  # Configuration for the OTP application
  def application do
    [applications: [],
     mod: {ExReloader, []}]
  end

  defp deps do
    [{ :exactor, github: "sasa1977/exactor" }]
  end
end
