import 'widgets';

import "dockview-core/dist/styles/dockview.css"
import { createDockview } from "dockview-core"

class Panel {
  get element() {
    return this._element
  }

  constructor() {
    this._element = document.createElement("div")
  }

  init(config) {
    this._element.id = config.params.id
    this._element.innerHTML = config.params.content.html
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
          className: x.theme,
          createComponent: (options) => {
            switch (options.name) {
              case "default":
                return new Panel(options)
            }
          }
        })

        api.onDidAddPanel((e) => {
          // callback
          let pane = `#${e.params.id}`
          Shiny.initializeInputs($(pane))
        })

        api.onDidActivePanelChange((e) => {
          let pane = `#${e.params.id}`
          Shiny.bindAll($(pane))
        })

        // Init panels
        x.panels.map((panel) => {
          return (api.addPanel({
            id: panel.id,
            component: "default",
            title: panel.title,
            params: {
              content: panel.content,
              id: panel.id
            }
            //position: panel.position
          }))
        });

        Shiny.addCustomMessageHandler('add-panel', (m) => {
          // TBD dynacally insert a panel
        })
      },

      resize: function (width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
