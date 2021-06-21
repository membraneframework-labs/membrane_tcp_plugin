defmodule Membrane.TCP.Sink do
  @moduledoc """
  Element that sends received buffers to a created TCP socket.
  """
  use Membrane.Sink

  alias Membrane.Buffer

  def_options ip_address: [
                type: :string,
                description: "Destination IP address to establish TCP connection with"
              ],
              port_no: [spec: 0..65535, description: "Port number"]

  def_input_pad :input,
    caps: :any,
    demand_unit: :buffers

  @impl true
  def handle_init(%__MODULE__{ip_address: ip_address, port_no: port_no}) do
    {:ok, socket} = :gen_tcp.connect(ip_address, port_no, [:binary, active: false])

    {:ok, %{socket: socket}}
  end

  @impl true
  def handle_prepared_to_playing(_context, state) do
    {{:ok, demand: :input}, state}
  end

  def handle_write(:input, %Buffer{payload: payload}, _context, %{socket: socket} = state) do
    case :gen_tcp.send(socket, payload) do
      :ok -> {{:ok, demand: :input}, state}
      {:error, reason} -> {{:error, reason}, state}
    end
  end
end
