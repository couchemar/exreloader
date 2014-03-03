##
## Inspired by mochiweb's reloader (Copyright 2007 Mochi Media, Inc.)
##
defmodule ExReloader do
  use Application.Behaviour

  def start do
    :ok = Application.start :exreloader
  end

  def start(_, _) do
    ExReloader.start_link()
  end

  use Supervisor.Behaviour

  def start_link() do
    :supervisor.start_link({:local, :exreloader_sup}, __MODULE__, [])
  end

  def init([]) do
    interval = System.get_env("EXRELOADER_INTERVAL") || 5000
    children = [ worker(ExReloader.Server, [interval]) ]
    supervise children, strategy: :one_for_one
  end

  ##

  def reload_module(module) do
    :error_logger.info_msg "Reloading module: #{inspect module}"
    :code.purge(module)
    :code.load_file(module)
  end

  def reload_file(file_name) do
    :error_logger.info_msg "Reloading from sources: #{file_name}"
    try do
      Code.load_file(file_name)
    rescue
      x in [CompileError] ->
        :error_logger.error_msg "Compile Error: #{inspect x.message}"
    end
  end

end

defmodule ExReloader.Server do
  use ExActor.Strict

  definit interval do
    {:ok, {timestamp, interval}, interval}
  end

  defcall stop, state: state do
    {:stop, :shutdown, :stopped, state}
  end

  definfo :timeout, state: {last, timeout} do
    now = timestamp
    run(last, now)
    {:noreply, {now, timeout}, timeout}
  end

  defp timestamp, do: :erlang.localtime

  defp run(from, to) do
    lc {module, filename} inlist :code.all_loaded, is_list(filename) do
      case File.stat(filename) do
        {:ok, File.Stat[mtime: mtime]} when mtime >= from and mtime < to ->
          :error_logger.info_msg "File #{inspect filename} modified. Reloading..."
          {:ok, filename} = String.from_char_list(filename)
          cond do
            String.ends_with? filename, ".ex" ->
              ExReloader.reload_file filename
            String.ends_with? filename, ".beam" ->
              ExReloader.reload_module module
            true ->
              :ok
          end
        {:ok, _} -> :unmodified
        {:error, :enoent} -> :gone
        other -> other
      end
    end
  end

end
