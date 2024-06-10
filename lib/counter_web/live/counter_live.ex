defmodule CounterWeb.CounterLive do
  use Phoenix.LiveView
  import CounterWeb.CoreComponents

  @topic "counter"

  def render(assigns) do
    ~H"""
    <.flash_group flash={@flash} />
    <div class="flex w-100 justify-center py-6">
      <div class="flex flex-col">
        <div class="mt-4 border p-2">
          <h1 class="w-fit text-2xl m-2">
            Current Count: <%= @count %>
          </h1>
          <button phx-click="increment" class="my-1 border-2 px-2 bg-slate-300">Increment</button>
          <button phx-click="decrement" class="my-1 border-2 px-2 bg-slate-300">Decrement</button>
        </div>
        <div class="mt-4 border p-2">
          <.form for={@form} phx-change="dothings">
            <.input field={@form[:input]} label="Type your message" />
          </.form>

          <h3>Message is: <%= @message %></h3>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    count = 0

    Phoenix.PubSub.subscribe(Counter.PubSub, @topic)

    {:ok,
     socket
     |> assign(:count, count)
     |> assign(:form, to_form(%{}))
     |> assign(:message, "")
     |> assign(:timer, nil)}
  end

  def handle_event(
        "increment",
        _unsigned_params,
        %{assigns: %{timer: timer, count: count}} = socket
      ) do
    Phoenix.PubSub.broadcast_from!(Counter.PubSub, self(), @topic, %{
      event: "increment",
      payload: %{message: "Hit Increment"}
    })

    {:noreply,
     socket
     |> increment(count, timer)}
  end

  def handle_event(
        "decrement",
        _unsigned_params,
        %{assigns: %{count: count, timer: timer}} = socket
      ) do
    Phoenix.PubSub.broadcast_from!(Counter.PubSub, self(), @topic, %{
      event: "decrement",
      payload: %{message: "Hit Decrement"}
    })

    {:noreply, socket |> decrement(count, timer)}
  end

  def handle_event("dothings", %{"input" => input}, socket) do
    {:noreply, socket |> assign(:message, input)}
  end

  def handle_info(:clear_flash, %{assigns: %{timer: timer}} = socket) do
    Process.cancel_timer(timer)
    {:noreply, socket |> assign(:timer, nil) |> clear_flash()}
  end

  def handle_info(
        %{event: "increment"} = message,
        %{assigns: %{timer: timer, count: count}} = socket
      ) do
    IO.inspect(message)
    {:noreply, socket |> increment(count, timer)}
  end

  def handle_info(
        %{event: "decrement"} = message,
        %{assigns: %{timer: timer, count: count}} = socket
      ) do
    IO.inspect(message)
    {:noreply, socket |> decrement(count, timer)}
  end

  defp schedule_clear_flash(socket) do
    timer = Process.send_after(self(), :clear_flash, 1500)
    socket |> assign(:timer, timer)
  end

  defp increment(socket, count, timer) do
    count = count + 1

    case timer do
      nil -> nil
      _ -> Process.cancel_timer(timer)
    end

    socket
    |> assign(:count, count)
    |> clear_flash()
    |> put_flash(:info, "Incremented")
    |> schedule_clear_flash()
  end

  defp decrement(socket, count, timer) do
    count = socket.assigns.count - 1

    case timer do
      nil -> nil
      _ -> Process.cancel_timer(timer)
    end

    socket
    |> assign(:count, count)
    |> clear_flash()
    |> put_flash(:info, "Decremented")
    |> schedule_clear_flash()
  end
end
