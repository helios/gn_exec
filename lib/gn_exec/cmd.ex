# defmodule GnExec.Cmd.Utils do
#   defmacro script(filename) do
#     script = File.read! filename
#     quote do
#         def script() do
#           unquote(script)
#         end #script
#     end #quote
#   end #macro
#   #
#   # defmacro module(filename) do
#   #   name = String.downcase Path.basename(filename, ".sh")
#   #   modulename = "GnExec.Cmd." <> String.capitalize(name)
#   #   # IO.inspect name
#   #   script = File.read! filename
#   #   quote do
#   #     defmodule unquote(String.capitalize(name)) do
#   #       def script() do
#   #         unquote(script)
#   #       end #script
#   #     end
#   #   end #quote
#   # end #macro
# end


defmodule GnExec.Cmd do
  alias GnExec.Registry
  @callback script(any) :: String.t

  @doc ~S"""
  Execute a command  and return its state and its stdout/stderr. Within loop would be possible to dipatch
  messages to some handler for monitoring the job activity (attach to some GenEnvent)

#      iex> #GnExec.Cmd.exec("ls")
#      {0, ['LICENSE\nREADME.md\n_build\nconfig\ndoc\nlib\nmix.exs\ntest\n'], nil}

  """
  def exec(job, output_callback, transfer_callback, retval_callback) do
    # TODO in case of exception the directory is not removed and task can not start
    #      make it more robust
    command = apply(job.module, :script, job.args) # calling the script function dynamically
    token_path = Application.get_env(:gn_exec, :jobs_path_prefix)
    |> Path.join(job.token)
    |> Path.absname # create the directory and run the script from there
    #File.mkdir!(token_path) # The directory should not exist, if it exists maybe another task is running the same job
    port=Port.open({:spawn, command},[:stream, :exit_status, :use_stdio, :stderr_to_stdout, {:cd, token_path}])
    # TODO: maybe introduce callback to set up the status for the job {progress: 0}
    {retval, _cache, _output} = loop(port, [],0, output_callback)
    # Pack the files generated by the job in a tar.gz archive

    # transfer files generated by the scripts and saved in the working directory
    # POST to token etc.... all files
    # consider to post also the checksum and verify that file is correct
    # Remove the local
    pack_file = pack(job, token_path) # prepare for moving files
    case transfer_callback.(job, pack_file) do # move files just in case
      :ok ->
        Registry.transferred job.token
        retval_callback.(retval) # this close all transimissions with outside
        # TODO: Do I need to keep track of what happened remotely ?
        File.rm_rf!(token_path)
        File.rm!(pack_file)
        case retval do
          0 -> Registry.complete(job.token)
            {:ok, retval}
          _ ->
            Registry.error(job.token)
            {:error, retval}
        end
      {:error, reason } ->
        Registry.error job.token
        {:error, reason }
    end
  end

  @doc ~S"""
  Timeout could be used in the future to check is the process is still alive or not

  """
  defp loop(port, cache, timeout, output) do
    receive do
      {^port, {:data, data}} ->
        output.(data)
        loop(port, [data | cache], timeout, output)
      {^port, {:exit_status, exit_status}} ->
        {exit_status, Enum.reverse(cache), output}
    end
  end

  @doc ~S"""
  Create a tar archive gzipped of the whole job directory. Returns the full path
  archive.

  """
  defp pack(job, path) do
    archive = "#{job.token}.tar.gz"
    {:ok, devnull} = File.open "/dev/null", [:write]
    System.cmd("tar",["-C", path, "-zcvf", archive, "."], stderr_to_stdout: true, into: IO.stream(devnull, :line))
    File.close(devnull)
    Path.absname(archive)
  end


  # import GnExec.Cmd.Utils, only: [module: 1]
end
