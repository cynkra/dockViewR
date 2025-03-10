import 'widgets';

import "dockview-core/dist/styles/dockview.css"
import { createDockview } from "dockview-core"

class Panel {
  get element() {
    return this._element
  }

  constructor() {
    this._element = document.createElement("div")
    this._element.style.color = "white"
  }

  init(parameters) {
    this._element.textContent = "Hello World"
  }
}

HTMLWidgets.widget({

  name: 'dock_view',

  type: 'output',

  factory: function (el, width, height) {

    // TODO: define shared variables for this instance

    return {

      renderValue: function (x, id = el.id) {

        // TODO: code to render the widget, e.g.
        const api = createDockview(document.getElementById(id), {
          className: "dockview-theme-abyss",
          createComponent: options => {
            switch (options.name) {
              case "default":
                return new Panel()
            }
          }
        })

        api.addPanel({
          id: "panel_1",
          component: "default",
          title: "Panel 1"
        })

        api.addPanel({
          id: "panel_2",
          component: "default",
          position: { referencePanel: "panel_1", direction: "right" },
          title: "Panel 2"
        })

      },

      resize: function (width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
