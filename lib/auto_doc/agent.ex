defmodule AutoDoc.Agent do
  def start_link do
    System.at_exit fn _ ->
      create_doc_file
    end
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def add_test_to_docs(conn, test_name) do
    Agent.get_and_update(__MODULE__, fn(docs) ->
      %{params: params, req_headers: req_headers, method: method, request_path: request_path} = conn
      request = %{params: params, req_headers: req_headers, method: method, request_path: request_path}
      %{resp_body: resp_body, status: status} = conn
      response = %{resp_body: IO.iodata_to_binary(resp_body), status: status}
      {docs, [%{test_name: test_name, request: request, response: response}| docs]}
    end)
    conn
  end

  def create_doc_file do
    tests = Agent.get(__MODULE__, fn(docs) -> docs  end)
    file_contents =
      Path.join([__DIR__, "..", "templates/api_docs.html.eex"])
      |> Path.expand
      |> EEx.eval_file([tests: tests])
    File.write!("#{Path.expand(".")}/api_docs.html", file_contents)
  end
end
