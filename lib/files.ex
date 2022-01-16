defmodule AwsCconf.Files do
  @moduledoc """
  Load credentials+config from ~/.aws "SHARED" files
  """

  def env_config, do: "AWS_CONFIG_FILE"
  @config_path_default "~/.aws/config"

  def env_shared_creds, do: "AWS_SHARED_CREDENTIALS_FILE"
  @creds_path_default "~/.aws/credentials"

  @type path :: String.t()
  @type overring_os_env :: String.t()

  @doc """
  Resolve the path (optionally via env) then open the stream
  """
  @spec resolved([path], [overring_os_env]) :: [keyword]
  def resolved(
        {p_creds, p_conf} \\ {@creds_path_default, @config_path_default},
        {e_creds, e_conf} \\ {env_shared_creds(), env_config()}
      ) do
    [{e_creds, p_creds}, {e_conf, p_conf}]
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
  @spec resolve_path({overring_os_env, path}) :: path
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
