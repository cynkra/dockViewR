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

        // Bind input/output only once, when they 
        // are in the DOM
        api.onDidActivePanelChange((e) => {
          let pane = `#${e.params.id}`
          let isBound = $(pane)
            .find('.shiny-bound-input, .shiny-bound-output')
            .length > 0
          if (!isBound) {
            console.log(`Binding panel ${e.params.id}.`)
            Shiny.bindAll($(pane))
          }
        })

        // Resize panel content on layout change
        // (useful so that plots or widgets resize correctly)
        api.onDidLayoutChange((e) => {
          window.dispatchEvent(new Event("resize"));
        })

        // Init panels
        x.panels.map((panel) => {
          let internals = {
            component: "default",
            params: {
              content: panel.content,
              id: panel.id
            }
          }
          let props = { ...panel, ...internals }
          return (api.addPanel(props))
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
