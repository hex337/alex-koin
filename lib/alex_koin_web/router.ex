defmodule AlexKoinWeb.Router do
  use AlexKoinWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", AlexKoinWeb do
    pipe_through(:api)

    resources("/users", UserController, except: [:new, :edit])
    resources("/wallets", WalletController, except: [:new, :edit])
    resources("/transactions", TransactionController, except: [:new, :edit])
    resources("/coins", CoinController, except: [:new, :edit])
  end
end
