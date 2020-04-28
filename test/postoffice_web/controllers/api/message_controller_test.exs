defmodule PostofficeWeb.Api.MessageControllerTest do
  use PostofficeWeb.ConnCase, async: true

  alias Postoffice.Messaging
  alias Postoffice.Messaging.PendingMessage
  alias Postoffice.Repo
  alias Postoffice.Fixtures

  @create_attrs %{
    attributes: %{},
    payload: %{"key" => "test", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]},
    topic: "test"
  }
  @invalid_attrs %{attributes: nil, payload: nil, topic: "test"}
  @bad_message_payload_by_topic %{
    attributes: %{},
    payload: %{"key" => "test", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]},
    topic: "no_topic"
  }
  @topic_attributes %{
    name: "functional_programming",
    origin_host: "http://fake.target",
    recovery_enabled: true
  }
  @publisher_attributes %{
    active: true,
    target: "http://fake.target",
    initial_message: 0,
    type: "http",
  }
  @message_attributes %{
    attributes: %{},
    payload: %{"key" => "test", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]},
    topic: "functional_programming"
  }

  setup %{conn: conn} do
    {:ok, _topic} = Messaging.create_topic(%{name: "test", origin_host: "example.com"})
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create message" do
    test "renders message when data is valid", %{conn: conn} do
      conn = post(conn, Routes.api_message_path(conn, :create), @create_attrs)
      assert %{"public_id" => id} = json_response(conn, 201)["data"]
    end

    test "renders errors when topic does not exists", %{conn: conn} do
      conn = post(conn, Routes.api_message_path(conn, :create), @bad_message_payload_by_topic)
      assert json_response(conn, 400)["data"]["errors"] == %{"topic" => ["is invalid"]}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.api_message_path(conn, :create), @invalid_attrs)

      assert json_response(conn, 400)["data"]["errors"] == %{
               "attributes" => ["can't be blank"],
               "payload" => ["can't be blank"]
             }
    end

    test "not mark message as pending when data is valid and topic has not associated publisher", %{conn: conn} do
      conn = post(conn, Routes.api_message_path(conn, :create), @create_attrs)

      assert length(Repo.all(PendingMessage)) == 0
    end

    test "mark message as pending when data is valid and topic has associated publisher", %{conn: conn} do
      Fixtures.create_topic(@topic_attributes)
      |> Fixtures.create_publisher(@publisher_attributes)

      conn = post(conn, Routes.api_message_path(conn, :create), @message_attributes)

      assert length(Repo.all(PendingMessage)) == 1
    end
  end
end
