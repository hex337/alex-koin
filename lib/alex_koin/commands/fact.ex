defmodule AlexKoin.Commands.Fact do
  alias AlexKoin.Factoids

  def execute() do
    fact_funcs = Factoids.__info__(:functions)

    {func_name, _arity} = Enum.random(fact_funcs)
    fact_str = apply(Factoids, func_name, [])
    {fact_str, nil}
  end
end
