defmodule MyResponseFactory do
  use FakeServer.ResponseFactory

  def person_response do
    ok(%{
      name: Faker.Name.name,
      email: Faker.Internet.free_email,
      company: %{name: Faker.Company.name, county: Faker.Address.country}
    }, %{"Content-Type" => "application/json"})
  end
end

defmodule FakeServer.Integration.ResponseFactoryTest do
  use ExUnit.Case

  import FakeServer

  test_with_server "basic factory usage" do
    customized_response = %{body: body} = MyResponseFactory.build(:person)
    person = Poison.decode!(body)

    route "/person", customized_response

    response = HTTPoison.get! FakeServer.address <> "/person"
    body = Poison.decode!(response.body)

    assert response.status_code == 200
    assert person["name"] == body["name"]
    assert person["email"] == body["email"]
    assert person["company"]["name"] == body["company"]["name"]
    assert person["company"]["country"] == body["company"]["country"]
  end

  test_with_server "setting custom attributes" do
    route "/person", MyResponseFactory.build(:person, name: "John", email: "john@myawesomemail.com")

    response = HTTPoison.get! FakeServer.address <> "/person"
    body = Poison.decode!(response.body)

    assert response.status_code == 200
    assert body["name"] == "John"
    assert body["email"] == "john@myawesomemail.com"
  end

  test_with_server "deleting an attribute" do
    route "/person", MyResponseFactory.build(:person, name: nil)

    response = HTTPoison.get! FakeServer.address <> "/person"
    body = Poison.decode!(response.body)

    assert response.status_code == 200
    assert body["name"] == nil
  end

  test_with_server "overriding a header" do
    route "/person", MyResponseFactory.build(:person, %{"Content-Type" => "application/x-www-form-urlencoded"})

    response = HTTPoison.get! FakeServer.address <> "/person"

    assert response.status_code == 200
    assert Enum.any?(response.headers, fn(header) -> header == {"Content-Type", "application/x-www-form-urlencoded"} end)
  end

  test_with_server "deleting a header" do
    route "/person", MyResponseFactory.build(:person, %{"Content-Type" => nil})

    response = HTTPoison.get! FakeServer.address <> "/person"

    assert response.status_code == 200
    refute Enum.any?(response.headers, fn(header) -> elem(header, 0) == "Content-Type" end)
  end

  test_with_server "create a list of responses" do
    person_list = MyResponseFactory.build_list(3, :person)

    route "/person", person_list

    Enum.each(person_list, fn(person) ->
      response = HTTPoison.get! FakeServer.address <> "/person"
      body = Poison.decode!(response.body)
      person = Poison.decode!(person.body)

      assert response.status_code == 200
      assert person["name"] == body["name"]
      assert person["email"] == body["email"]
      assert person["company"]["name"] == body["company"]["name"]
      assert person["company"]["country"] == body["company"]["country"]
    end)
  end
end
