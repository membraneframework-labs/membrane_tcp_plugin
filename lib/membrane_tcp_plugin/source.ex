defmodule Membrane.TCP.Source do
  @moduledoc """
  Element that reads packets from a TCP socket and sends their payloads through the output pad.
  """
  use Membrane.Source

  alias Membrane.Buffer

  def_options ip_address: [
                type: :string,
                description: "IP address to establish TCP connection with"
              ],
              port_no: [type: :integer, description: "Port number"],
              chunk_size: [
                type: :integer,
                spec: pos_integer,
                default: 2048,
                description: "Size of chunks being read"
              ]

  def_output_pad :output, caps: :any

  @impl true
  def handle_init(%__MODULE__{ip_address: ip_address, port_no: port_no, chunk_size: size}) do
    {:ok, socket} = :gen_tcp.connect(ip_address, port_no, [:binary, active: false])

    {:ok, %{socket: socket, chunk_size: size}}
  end

  @impl true
  def handle_demand(:output, _size, :buffers, _ctx, %{chunk_size: chunk_size} = state),
    do: supply_demand(chunk_size, [redemand: :output], state)

  def handle_demand(:output, size, :bytes, _ctx, state),
    do: supply_demand(size, [], state)

  defp supply_demand(size, redemand, %{socket: socket} = state) do
    with {:ok, payload} <- :gen_tcp.recv(socket, size) do
      {{:ok, [buffer: {:output, %Buffer{payload: payload}}] ++ redemand}, state}
    else
      :eof -> {{:ok, end_of_stream: :output}, state}
      {:error, reason} -> {{:error, reason}, state}
    end
  end
end
