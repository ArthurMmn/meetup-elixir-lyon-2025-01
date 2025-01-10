# Extrait du Meetup

## Présentation du Framework

[Phoenix](https://www.phoenixframework.org/) est un framework web d'Elixir, en 1.0 depuis 2015. C'est une librairie pilier de l'écosystème Elixir et la base de nombreux projets web.

Depuis 2019, les efforts de développement autour de la librairie Phoenix se sont concentrés sur [LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html), une librairie complémentaire à Phoenix qui permet de créer des applications web interactives grâce à une connexion persistante entre le serveur et le client.

5 ans plus tard, la version 1.0 de LiveView est sortie. Ces quelques années de développement ont apporté de nombreuses améliorations et fonctionnalités (et avec elles leur lot d'instabilité), elles ont notamment permis de combler certaines lacunes en termes d'interaction avec le navigateur.

## LiveView en bref

cf [ScrabbleCheckerLive](./lib/lv_meetup_web/scrabble_checker_live.ex)

Une LiveView est découpée en plusieurs parties. Pour faire simple, elles sont présentées ici dans le même fichier, mais il est possible de les séparer en plusieurs fichiers et d'avoir des discussions infinies sur la meilleure façon de les organiser.

- `mount/2` : fonction qui est appelée lors de la création de la LiveView, elle permet de récupérer les données nécessaires à l'affichage de la page.
- `render/1` : fonction qui est appelée à chaque mise à jour de la LiveView, elle permet de générer le HTML à afficher.
- `handle_*/(2|3)` : fonctions qui sont appelées lors d'évènements, elles permettent de mettre à jour la LiveView en fonction des messages que reçoit le process.

```elixir
def render(assigns) do
  ~H"""
    [...]
    <div>
      <.form phx-change="search-words">
        <.input field={f[:text]} type="text" placeholder="Mots commençant par...." />
      </.form>
      <ul>
        <li :for={word <- @words}>
          {word}
        </li>
      </ul>
    </div>
    [...]
  """
end

def mount(_params, _session, socket) do
  socket =
    socket
    |> assign(:words, [])

  {:ok, socket}
end

def handle_event("search-words", %{"text" => text}, socket) do
  words = Scrabble.search(text, 15)

  {:noreply, assign(socket, :words, words)}
end
```

Ici très simplement, le process s'initialise au chargement de la page avec une liste de mots vide. Lorsque l'utilisateur tape un mot dans le champ de recherche, la fonction `handle_event/3` est appelée, elle récupère les mots correspondants et les affiche.

La librairie permet de réagir à plusieurs types d'évènements : clic, changement de valeur, soumission de formulaire, mise à jour de l'URL, etc. Quand les `assigns` sont mis à jour, le template est recalculé et les changements sont envoyés au client.

## LiveView et JavaScript

cf [ScrabbleFuzzyLive](./lib/lv_meetup_web/scrabble_fuzzy_live.ex) et les [Hooks](assets/js/hooks.js)

Phoenix met aussi à disposition une librairie permettant directement d'interagir avec le navigateur [LiveView.JS](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html). Elle permet de contrôler l'état de la page via des objets Elixir traduits en commandes JavaScript lors du rendu. Pour ces cas simples, l'action est intégrée au template et ne nécessite pas d'aller-retour vers le serveur. Elle peut même être utilisée en dehors de pages LiveView.

```elixir
def render(assigns) do
  ~H"""
    [...]
    <button phx-click={JS.toggle(".toggle-me")}>Basculer l'affichage</button>
    <div id="toggle-me">
      Bonjour Monde !
    </div>
    [...]
  """
end
```

Les [Hooks](https://hexdocs.pm/phoenix_live_view/js-interop.html#client-hooks-via-phx-hook) permettent des interactions encore plus riches grâce à une API JavaScript servant de pont entre le process LiveView sur le serveur et l'application sur le navigateur.

```elixir
def render(assigns) do
  ~H"""
    [...]
    <div id="fuzzy" phx-hook="FuzzyMatchHook" data-list={[...]}>
      <div>
        <.input type="text" fuzzy-input />
      </div>
      <ul fuzzy-wrapper></ul>
    </div>
    [...]
  """
end
```

```javascript
Hooks.FuzzyMatchHook = {
  matchables() {
    return JSON.parse(this.el.getAttribute(DATA_ATTR));
  },
  input() {
    return this.el.querySelector(INPUT_SELECTOR);
  },
  mounted() {
    let opts = {[...]};

    let matcher = new uFuzzy(opts);
    const data = this.matchables();
    const wrapper = this.el.querySelector(WRAPPER_SELECTOR);

    this.input().addEventListener("input", (e) => {
      wrapper.innerHTML = "";
      [idx, _, _] = matcher.search(data, e.target.value || []);
      idx.slice(0, 10).forEach((idx) => {
        const item = document.createElement("li");
        item.textContent = data[idx];
        wrapper.appendChild(item);
      });
    });
  },
};
```

Les valeurs du dictionnaire sont envoyées au client lors du premier chargement de la page, puis la recherche est effectuée en local au lieu de faire des allers-retours vers le serveur. Cela permet notamment d'interagir avec des librairies JavaScript complexes qui auraient besoin de leur propre état (tableur, grapheur) voire d'utiliser des frameworks front-end comme React.

Ces interactions sont très puissantes et versatiles. Si cet exemple ne nécessite pas de communication avec le serveur, il est possible de communiquer avec le serveur ou de réagir à la mise à jour de la page.

## LiveView en tant que process

cf [ScrabbleAdminLive](./lib/lv_meetup_web/scrabble_admin_live.ex)

Phoenix et LiveView se reposent sur le modèle de process d'Elixir (hérité d'Erlang et de sa VM). Chaque LiveView est un process qui tourne en parallèle du serveur et qui est capable de réagir à des évènements.

On peut ainsi inspecter la BEAM pour consulter les process en cours, inspecter leur état et interagir avec eux.

```elixir
@checked_module LvMeetupWeb.ScrabbleCheckerLive

Enum.each(
  :erlang.processes(),
  fn pid ->
    case :erlang.process_info(pid, :dictionary) do
      {:dictionary, dict} ->
        Enum.any?(dict, fn
          {:"$initial_call", {module, _, _}} when module == @checked_module ->
            send(pid, {:admin, :maintenance})

          _ ->
            nil
        end)

      _ ->
      nil
    end
end)
```

```elixir
def handle_info({:admin, :maintenance}, socket) do
  socket =
    socket
    |> redirect(to: ~p"/maintenance")

  {:noreply, socket}
end
```

Dans cet exemple, on va récupérer les process en cours du module qui nous intéresse pour leur envoyer un message, le process réagit à ce message grâce au callback `handle_info/2`.

Phoenix fournit des outils de plus haut niveau pour simplifier les interactions entre les process. Par exemple, chaque process peut s'abonner ou publier sur un service de Publication/Abonnement pour réagir à des évènements.

```elixir
  def mount(_, _, socket) do
      HistoryPubsub.subscribe()

      socket =
        socket
        |> stream(:messages, [])

      {:ok, socket}
    end

    def handle_info({"Elixir.LvMeetup.HistoryPubsub", msg}, socket) do
      socket =
        socket
        |> stream_insert(:messages, msg)

      {:noreply, socket}
    end
```

```elixir
  def handle_params(%{"mot" => mot}, _, socket) do
      score = Scrabble.result(mot)

      process_name =
        self()
        |> :erlang.pid_to_list()
        |> Enum.join("-")

      HistoryPubsub.publish(%{
        id: :erlang.unique_integer(),
        msg: "#{process_name} a recherché #{mot}"
      })

      {:noreply, assign(socket, :score, score)}
    end
```

Ici la LiveView de ScrabbleChecker publie un message à chaque recherche de mot sur le canal `Elixir.LvMeetup.HistoryPubsub`, la LiveView de ScrabbleAdmin qui s'y est abonnée, réagit à chaque nouveau message en l'ajoutant à l'historique.

## Conclusion

À titre personnel, j'ai été agréablement surpris par le confort de développement et la richesse des interactions possibles entre le serveur et le navigateur, un des points faibles des anciennes versions de Phoenix.

C'est tout de même un outil complexe, le coût des WebSockets et des allers-retours vers le serveur n'est pas négligeable et peut être difficile à estimer. Ça reste un bon couteau suisse, notamment pour le prototypage et pour s'affranchir de la complexité des frameworks front-end lourds.
