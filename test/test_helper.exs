ExUnit.configure(exclude: [skip: true])
Application.ensure_all_started(:faker)
ExUnit.start()
