ExUnit.configure(exclude: [skip: true])
Application.ensure_all_started(:faker)
Application.ensure_all_started(:fake_server)
ExUnit.start()
