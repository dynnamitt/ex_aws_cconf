defmodule AwsCconf do
  @moduledoc """
  Combine the ~/.aws "SHARED" files

  """

  @creds_kv_subset ["aws_access_key_id", "aws_secret_access_key", "aws_session_token"]
  # OVERLOOK other kv's

  # TRIGGERS for new "STS Session credentials"
  # TODO structs?
  # @attr_src_p "role_arn"
  # @attr_mfa "mfa_serial"
  # @attr_sso_url "sso_start_url"

  @doc """
  Parse & merge config streams.

  Selects a profile (in each stream) then merge the keyvalues.

  .aws/credentials ALWAYS come first,
  then .aws/config (and more if appended)
  """
  @spec combine(String.t(), {map, map}, bool) :: map
  def combine(
        profile_name \\ "default",
        {credentials, config},
        strict_cred_field_selection? \\ true
      ) do
    p_creds =
      credentials
      |> get_credentials_p(profile_name)
      # Strict according to aws doc
      |> then(
        &if strict_cred_field_selection? do
          Map.take(&1, @creds_kv_subset)
        else
          &1
        end
      )

    p_conf = get_config_p(config, profile_name)
    merge_profile_kvs([p_creds, p_conf])
  end

  # FIXME all 3 could be :error !!
  defp get_credentials_p(profiles, profile) do
    profiles[profile]
    # TODO Map.filter(@creds_kv_subset)
  end

  defp get_config_p(profiles, profile) when profile == "default" do
    profiles[profile]
  end

  defp get_config_p(profiles, profile) do
    profiles
    |> Map.keys()
    # TODO compile regex to avoid special-char injection
    |> Enum.find(&String.match?(&1, ~r/profile\ *#{profile}/))
    |> then(&profiles[&1])
  end

  # FIXME both could be nil !!
  def merge_profile_kvs(profile_maps) do
    profile_maps
    |> Enum.reduce(fn x, acc -> Enum.into(acc, x) end)
  end

  # def extract_kvs(profiles, kv_subset \\ []) do
  #   1
  # end
end
