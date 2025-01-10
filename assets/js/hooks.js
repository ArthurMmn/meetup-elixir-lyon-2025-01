import uFuzzy from "@leeoniya/ufuzzy";

let Hooks = {};

const INPUT_SELECTOR = "input[fuzzy-input]";
const WRAPPER_SELECTOR = "ul[fuzzy-wrapper]";
const DATA_ATTR = "data-list";

/**
 * @type {import("phoenix_live_view").ViewHook}
 */
Hooks.FuzzyMatchHook = {
  matchables() {
    return JSON.parse(this.el.getAttribute(DATA_ATTR));
  },
  input() {
    return this.el.querySelector(INPUT_SELECTOR);
  },
  mounted() {
    let opts = {
      intraMode: 0,
    };

    let matcher = new uFuzzy(opts);
    const data = this.matchables();
    const wrapper = this.el.querySelector(WRAPPER_SELECTOR);

    const searchWord = (word) => this.pushEvent("search", { mot: word });

    this.input().addEventListener("input", (e) => {
      if (e.target.value == "" || !e.target.value) return;

      wrapper.innerHTML = "";

      [idx, _, _] = matcher.search(data, e.target.value || []);

      idx.slice(0, 10).forEach((idx) => {
        const word = data[idx];
        const item = document.createElement("li");
        item.className = "p-1 rounded bg-zinc-100 cursor-pointer";
        item.textContent = word;
        item.addEventListener("click", () => searchWord(word));
        wrapper.appendChild(item);
      });
    });
  },
};

export { Hooks };
