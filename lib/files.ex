defmodule AwsCconf.Files do
  @moduledoc """
  Load credentials+config from ~/.aws "SHARED" files
  """
  @config_env "AWS_CONFIG_FILE"
  @config_path_default "~/.aws/config"

  @shared_creds_env "AWS_SHARED_CREDENTIALS_FILE"
  @creds_path_default "~/.aws/credentials"

  @type path :: String.t()

  @doc """
  Resolve the path (optionally via env) then open the stream
  """
  @spec resolved([path], [String.t()]) :: [keyword]
  def resolved(
        load_paths \\ [@creds_path_default, @config_path_default],
        override_path_envs \\ [@shared_creds_env, @config_env]
      ) do
    override_path_envs
    |> Enum.zip(load_paths)
    |> Enum.map(&resolve_path/1)
    |> Enum.map(&File.stream!/1)
    |> Enum.map(
      &try do
        ConfigParser.parse_stream(&1)
      rescue
        e -> {:error, e.reason}
      end
    )
  end

  # Find the path to file
  @spec resolve_path({String.t(), path}) :: path
  defp resolve_path({override_env, default_path}) do
    override_env
    |> System.get_env()
    |> case do
      nil -> default_path
      path -> path
    end
    |> Path.expand()
  end
end
