defmodule Pyc.Invalid do
  @moduledoc """
  Common exception to raise errors from inside `Pyc`
  """
  defexception [:source, :reason, :message]

  @doc false
  def exception(source: source, reason: reason) do
    message = ~s"""
    Error handling the operation inside #{source.__struct__}.

    Reason: #{inspect(reason)}.
    """

    %Pyc.Invalid{message: message, source: source, reason: reason}
  end
end
