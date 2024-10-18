defmodule GrowthWeb.ChildFormComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="card bg-base-300 shadow-md rounded-lg p-6">
      <form phx-submit="save_child">
        <label class="form-control w-full max-w-xs">
          <div class="label">
            <span class="label-text">Nome</span>
          </div>
          <input
            type="text"
            name="child[name]"
            class="input input-bordered input-primary"
            placeholder="Nome"
            required
          />
        </label>

        <label class="form-control w-full max-w-xs">
          <div class="label">
            <span class="label-text">Data de nascimento</span>
          </div>
          <input type="date" name="child[birthday]" class="input input-bordered input-primary" required />
        </label>

        <label class="form-control w-full max-w-xs">
          <div class="label">
            <span class="label-text">Sexo</span>
          </div>
          <select name="child[gender]" class="select select-bordered select-primary">
            <option value="female">Menina</option>
            <option value="male">Menino</option>
          </select>
        </label>

        <div class="text-center mt-4">
          <button type="submit" class="btn btn-primary">Próximo</button>
        </div>
      </form>
    </div>
    """
  end
end
