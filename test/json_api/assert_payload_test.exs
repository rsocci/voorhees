defmodule Voorhees.Test.JSONApi.AssertPayloadTest do
  use ExUnit.Case

  test "does not throw error when the payloads match" do
    payload = %{
      "data" => %{
        "type" => "user",
        "id" => "1",
        "attributes" => %{
          "email" => "test@example.com",
          "name" => "Tester"
        }
      }
    }

    Voorhees.JSONApi.assert_payload payload, %{
      data: %{
        id: "1",
        type: "user",
        attributes: %{
          email: "test@example.com",
          name: "Tester"
        }
      }
    }
  end

  test "does not throw error when the payload has attributes not in the expected payload" do
    payload = %{
      "data" => %{
        "type" => "user",
        "id" => "1",
        "attributes" => %{
          "email" => "test@example.com",
          "name" => "Tester"
        }
      }
    }

    Voorhees.JSONApi.assert_payload payload, %{
      data: %{
        id: "1",
        type: "user",
        attributes: %{
          name: "Tester"
        }
      }
    }
  end

  test "does not throw errors when list's ordering differs with the `ignore_list_order` flag" do
    payload = %{
      "data" => [%{
        "type" => "user",
        "id" => "1",
        "attributes" => %{
          "email" => "test@example.com",
          "name" => "Tester"
        }
      },%{
        "type" => "user",
        "id" => "2",
        "attributes" => %{
          "email" => "test@example.com",
          "name" => "Tester"
        }
      }],
      "included" => [%{
        "type" => "member",
        "id" => "1",
        "attributes" => %{
          "email" => "test@example.com",
          "name" => "Tester"
        }
      },%{
        "type" => "member",
        "id" => "2",
        "attributes" => %{
          "email" => "test@example.com",
          "name" => "Tester"
        }
      }]
    }

    Voorhees.JSONApi.assert_payload(payload, %{
      data: [%{
        id: "2",
        type: "user",
        attributes: %{
          name: "Tester"
        }
      },%{
        id: "1",
        type: "user",
        attributes: %{
          name: "Tester"
        }
      }],
      included: [%{
        id: "2",
        type: "member",
        attributes: %{
          name: "Tester"
        }
      },%{
        id: "1",
        type: "member",
        attributes: %{
          name: "Tester"
        }
      }]
    }, ignore_list_order: true)
  end

  test "throws an error when the actual payload is missing attributes in data as a map" do
    payload = %{
      "data" => %{
        "type" => "user",
        "id" => "1",
        "attributes" => %{
          "name" => "Tester"
        }
      }
    }

    assert_raise ExUnit.AssertionError, """
    Payload did not match expected

    "data" did not match expected
    Expected:
      %{"attributes" => %{"email" => "test@example.com", "name" => "Tester"}, "id" => "1", "type" => "user"}
    Actual (filtered):
      %{"attributes" => %{"name" => "Tester"}, "id" => "1", "type" => "user"}
    Actual (untouched):
      %{"attributes" => %{"name" => "Tester"}, "id" => "1", "type" => "user"}
    """, fn ->
      Voorhees.JSONApi.assert_payload payload, %{
        data: %{
          id: "1",
          type: "user",
          attributes: %{
            email: "test@example.com",
            name: "Tester"
          }
        }
      }
    end
  end

  test "throws an error when the actual payload is missing attributes in data as a list" do
    payload = %{
      "data" => [%{
        "type" => "user",
        "id" => "1",
        "attributes" => %{
          "name" => "Tester"
        }
      }]
    }

    assert_raise ExUnit.AssertionError, """
    Payload did not match expected

    "data" did not match expected

    Resource at index 0 did not match
    Expected:
      %{"attributes" => %{"email" => "test@example.com", "name" => "Tester"}, "id" => "1", "type" => "user"}
    Actual (filtered):
      %{"attributes" => %{"name" => "Tester"}, "id" => "1", "type" => "user"}
    Actual (untouched):
      %{"attributes" => %{"name" => "Tester"}, "id" => "1", "type" => "user"}
    """, fn ->
      Voorhees.JSONApi.assert_payload payload, %{
        data: [%{
          id: "1",
          type: "user",
          attributes: %{
            email: "test@example.com",
            name: "Tester"
          }
        }]
      }
    end
  end

  test "throws an error when the actual payload has a different value for attributes in data as a map" do
    payload = %{
      "data" => %{
        "type" => "user",
        "id" => "1",
        "attributes" => %{
          "name" => "Tester1"
        }
      }
    }

    assert_raise ExUnit.AssertionError, """
    Payload did not match expected

    "data" did not match expected
    Expected:
      %{"attributes" => %{"name" => "Tester"}, "id" => "1", "type" => "user"}
    Actual (filtered):
      %{"attributes" => %{"name" => "Tester1"}, "id" => "1", "type" => "user"}
    Actual (untouched):
      %{"attributes" => %{"name" => "Tester1"}, "id" => "1", "type" => "user"}
    """, fn ->
      Voorhees.JSONApi.assert_payload payload, %{
        data: %{
          id: "1",
          type: "user",
          attributes: %{
            name: "Tester"
          }
        }
      }
    end
  end

  test "throws an error when the actual payload has a different value for attributes as a list" do
    payload = %{
      "data" => [%{
        "type" => "user",
        "id" => "1",
        "attributes" => %{
          "name" => "Tester1"
        }
      }]
    }

    assert_raise ExUnit.AssertionError, """
    Payload did not match expected

    "data" did not match expected

    Resource at index 0 did not match
    Expected:
      %{"attributes" => %{"name" => "Tester"}, "id" => "1", "type" => "user"}
    Actual (filtered):
      %{"attributes" => %{"name" => "Tester1"}, "id" => "1", "type" => "user"}
    Actual (untouched):
      %{"attributes" => %{"name" => "Tester1"}, "id" => "1", "type" => "user"}
    """, fn ->
      Voorhees.JSONApi.assert_payload payload, %{
        data: [%{
          id: "1",
          type: "user",
          attributes: %{
            name: "Tester"
          }
        }]
      }
    end
  end

  test "throws an error when the actual payload has a differing list item as a list" do
    payload = %{
      "data" => [%{
        "id" => "1",
        "type" => "user",
        "attributes" => %{
          "name" => "Tester"
        }
        }, %{
        "type" => "user",
        "id" => "2",
        "attributes" => %{
          "name" => "Tester2"
        }
      }]
    }

    assert_raise ExUnit.AssertionError, """
    Payload did not match expected

    "data" did not match expected

    Resource at index 1 did not match
    Expected:
      %{"attributes" => %{"name" => "Tester3"}, "id" => "2", "type" => "user"}
    Actual (filtered):
      %{"attributes" => %{"name" => "Tester2"}, "id" => "2", "type" => "user"}
    Actual (untouched):
      %{"attributes" => %{"name" => "Tester2"}, "id" => "2", "type" => "user"}
    """, fn ->
      Voorhees.JSONApi.assert_payload payload, %{
        data: [
          %{
            id: "1",
            type: "user",
            attributes:
              %{
                name: "Tester"
              }
          },%{
            id: "2",
            type: "user",
            attributes:
              %{
                name: "Tester3"
              }
          }
        ]
      }
    end
  end
end
