defmodule Valkyrie.Validators do
  @moduledoc false

  def get_invalid_fields(payload, schema) do
    Enum.map(schema, fn %{name: name} = field ->
      if not_header?(field, payload) do
        field_present?(field, payload)
      else
        name
      end
    end)
    |> List.flatten()
    |> Enum.reject(fn field -> field == nil end)
  end

  defp field_present?(%{name: name, type: "map", subSchema: sub_schema}, payload) do
    get_invalid_fields(payload[String.to_atom(name)], sub_schema)
  end

  defp field_present?(
         %{name: name, type: "list", itemType: "map", subSchema: sub_schema},
         payload
       ) do
    schemas_with_maps = Enum.zip(sub_schema, payload[String.to_atom(name)])

    Enum.map(schemas_with_maps, fn {schema, map} ->
      get_invalid_fields(map, schema)
    end)
  end

  defp field_present?(%{name: name}, payload) do
    field_name =
      name
      |> String.downcase()
      |> String.to_atom()

    payload_keys =
      payload
      |> Map.keys()
      |> Enum.map(fn key ->
        key
        |> Atom.to_string()
        |> String.downcase()
        |> String.to_atom()
      end)

    if field_name in payload_keys do
      nil
    else
      Atom.to_string(field_name)
    end
  end

  defp not_header?(%{name: name}, payload) do
    atom_name = String.to_atom(name)

    case Map.get(payload, atom_name) do
      value when not is_binary(value) ->
        true

      value ->
        String.downcase(value) != String.downcase(name)
    end
  end
end
