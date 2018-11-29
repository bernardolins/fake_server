defmodule FakeResponseFactory do
  use FakeServer.ResponseFactory

  def person_response do
    ok!(%{
      name: Faker.Name.name,
      email: Faker.Internet.free_email,
      company: %{name: Faker.Company.name, county: Faker.Address.country}
    }, %{"Content-Type" => "application/json"})
  end

  def customized_404_response do
    not_found!(%{message: "This item was not found!"}, %{"Content-Type" => "application/json"})
  end
end
