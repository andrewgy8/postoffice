defmodule Postoffice.PubSubIngester.Adapters.Impl do
  @moduledoc false

  @callback get(conn :: Map, sub_name :: String) :: {:ok, Map} | {:error, reason :: String}
  @callback confirm(conn :: Map, ack_ids :: List) :: {:ok, Map}
  @callback connect() :: Map
end
