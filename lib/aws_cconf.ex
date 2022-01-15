defmodule AwsCconf do
  @moduledoc """
  Combine the ~/.aws "SHARED" files

  """

  @creds_attrs_subset [
    "aws_access_key_id",
    "aws_secret_access_key",
    "aws_session_token"
  ]

  # TRIGGERS for new "STS Session credentials"
  @attr_src_p "source_profile"
  @attr_mfa "mfa_serial"
  @attr_sso_url "sso_start_url"

  @doc """
  Parse & merge config streams.

  Selects a profile (in each stream) then merge the keyvalues.

  .aws/credentials ALWAYS come first,
  then .aws/config (and more if appended)
  """
  @spec combine(String.t(), {map, map}, bool) :: map
  def combine(
        pname \\ "default",
        {creds, config},
        strict_creds_subset? \\ true,
        recurse_src_profile_attr? \\ true
      ) do
    attrs_list =
      case [creds[pname], get_config_p(config, pname)] do
        [nil, conf_p] ->
          [conf_p]

        [creds_p, nil] ->
          [creds_p]

        [creds_p, conf_p] when strict_creds_subset? ->
          [Map.take(creds_p, @creds_attrs_subset), conf_p]

        [creds_p, conf_p] ->
          [creds_p, conf_p]
      end

    attrs = merge_profile_attrs(attrs_list)

    case attrs do
      %{@attr_src_p => src_p} when recurse_src_profile_attr? ->
        %{
          attrs
          | @attr_src_p => combine(src_p, {creds, config}, strict_creds_subset?, false)
        }

      _ ->
        attrs
    end
  end

  defp get_config_p(profiles, pname) when pname == "default" do
    profiles[pname]
  end

  defp get_config_p(profiles, pname) do
    profiles
    |> Map.keys()
    # TODO compile regex to avoid special-char injection
    |> Enum.find(&String.match?(&1, ~r/profile\ *#{pname}/))
    |> then(&profiles[&1])
  end

  defp merge_profile_attrs(profile_maps) do
    profile_maps
    # |> IO.inspect()
    |> Enum.reduce(fn x, acc -> Enum.into(acc, x) end)
  end
end
