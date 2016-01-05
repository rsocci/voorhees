defmodule Voorhees.JSONApi do
  import ExUnit.Assertions

  def assert_schema(%{"data" => list } = actual , expected) when is_list(list) do
    list
    |> Enum.map(&(_assert_resource(&1, expected)))

    if included = actual["included"] do
      included
      |> Enum.map(&(_assert_resource(&1, expected)))
    end

    actual
  end

  def assert_schema(%{"data" => resource } = actual , expected) when is_map(resource) do
    _assert_resource(resource, expected)

    actual
  end

  defp _assert_resource(resource, expected) do
    %{"type" => type, "attributes" => attributes} = resource

    expected
    |> Map.fetch(String.to_atom(type))
    |> case do
      :error ->
        assert false, "Expected schema did not contain type: #{type}"
      {:ok, expected_schema} ->
        %{attributes: expected_attributes} = expected_schema
        _assert_attributes(attributes, expected_attributes)
    end
  end

  defp _assert_attributes(attributes, expected_attributes) do
    attribute_names = attributes
    |> Map.keys
    |> Enum.map(&(String.to_atom(&1)))

    extra_attributes = attribute_names -- expected_attributes
    assert [] == extra_attributes, "Payload contained additional attributes: #{extra_attributes |> Enum.join(", ")}"

    missing_attributes = expected_attributes -- attribute_names
    assert [] == missing_attributes, "Payload was missing attributes: #{missing_attributes |> Enum.join(", ")}"
  end

  def assert_payload(actual, expected, options \\ []) do
    assert Voorhees.matches_payload?(actual, expected, options), error_message(actual, expected)

    actual
  end

  defp error_message(actual, expected) do
    full_message = "Payload did not match expected\n\n"
    expected = normalize_map_keys(expected)

    with {:ok, actual_data} <- Map.fetch(actual, "data"),
         {:ok, expected_data} <- Map.fetch(expected, "data") do
           compare_resources(actual_data, expected_data)
           |> case do
             {:error, message} -> full_message = full_message <> "\"data\" did not match expected\n" <> message
             :ok -> nil
           end
         end
  end

  defp compare_resources(actual, expected) when is_map(actual) do
    expected = normalize_map_keys(expected)
    filtered_actual = remove_extra_info(actual, expected)

    if (filtered_actual == expected) do
      :ok
    else
      {:error, """
        Expected:
          #{inspect expected}
        Actual (filtered):
          #{inspect filtered_actual}
        Actual (untouched):
          #{inspect actual}
        """}
    end
  end

  defp compare_resources(actual, expected) when is_list(actual) do
    message = actual
    |> Enum.zip(expected)
    |> Enum.map(fn
      {actual_resource, expected_resource} ->
        compare_resources(actual_resource, expected_resource)
    end)
    |> Enum.with_index
    |> Enum.reduce("", fn
      {{:error, message}, index}, acc ->
        acc <> "\nResource at index #{index} did not match\n" <> message
      _, acc -> acc
    end)

    {:error, message}
  end

  defp remove_extra_info(actual, expected) do
    actual =
      actual
      |> clean_key(expected, "attributes")
      # |> clean_key(expected, "relationships")

  end

  defp clean_key(actual, expected, key) do
    %{^key => actual_value} = actual
    %{^key => expected_value} = expected

    actual
    |> Map.put(key, clean_value(actual_value, normalize_map_keys(expected_value)))
  end

  defp clean_value(actual_value, expected_value) when is_map(actual_value) do
    expected_keys = Map.keys(expected_value)

    Enum.reduce(actual_value, %{}, fn
      {key, value}, acc ->
        if Enum.member?(expected_keys, key) do
          Map.put(acc, key, value)
        else
          acc
        end
    end)
  end

  defp clean_value(actual_value, expected_value) when is_list(actual_value) do
    actual_value
    |> Enum.with_index
    |> Enum.map(fn
      {value, index} ->
        clean_value(value, Enun.at(expected_value, index))
    end)
  end

  defp clean_value(actual_value, _expected_value), do: actual_value

  defp normalize_map_keys(map) when is_map(map) do
    map
    |> Enum.map(&normalize_key/1)
    |> Enum.into(%{})
  end

  defp normalize_key({key, value}) when is_atom(key), do: {Atom.to_string(key), value}
  defp normalize_key(tuple), do: tuple
end
