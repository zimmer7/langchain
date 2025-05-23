defmodule LangChain.ChatModels.ChatModel do
  require Logger
  alias LangChain.Message
  alias LangChain.MessageDelta
  alias LangChain.Function
  alias LangChain.LangChainError
  alias LangChain.Utils

  @type call_response ::
          {:ok, Message.t() | [Message.t()] | [MessageDelta.t()]} | {:error, LangChainError.t()}

  @type tool :: Function.t()
  @type tools :: [tool()]

  @type t :: Ecto.Schema.t()

  @callback call(
              t(),
              String.t() | [Message.t()],
              [LangChain.Function.t()]
            ) :: call_response()

  @callback serialize_config(t()) :: %{String.t() => any()}

  @callback restore_from_map(%{String.t() => any()}) :: {:ok, struct()} | {:error, String.t()}

  @doc """
  Create a serializable map from a ChatModel's current configuration that can
  later be restored.
  """
  def serialize_config(%chat_module{} = model) do
    # plucks the module from the struct and, because of the behaviour, assumes
    # the module defines a `serialize_config/1` function that is executed.
    chat_module.serialize_config(model)
  end

  @doc """
  Restore a ChatModel from a serialized config map.
  """
  @spec restore_from_map(nil | %{String.t() => any()}) :: {:ok, struct()} | {:error, String.t()}
  def restore_from_map(nil), do: {:error, "No data to restore"}

  def restore_from_map(%{"module" => module_name} = data) do
    case Utils.module_from_name(module_name) do
      {:ok, module} ->
        module.restore_from_map(data)

      {:error, _reason} = error ->
        error
    end
  end
end
