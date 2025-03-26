import 'widgets';
import 'dockview-core/dist/styles/dockview.css'
import { createDockview } from "dockview-core";

import { Panel, RightHeader } from '../modules/components'
import { matchTheme, addPanel } from '../modules/utils';

HTMLWidgets.widget({

  name: 'dockview',

  type: 'output',

  factory: function (el, width, height) {

    // TODO: define shared variables for this instance

    return {

      renderValue: function (x, id = el.id) {

        // TODO: code to render the widget, e.g.
        const api = createDockview(document.getElementById(id), {
          theme: matchTheme(x.theme),
          createRightHeaderActionComponent: (options) => {
            return new RightHeader(options)
          },
          createComponent: (options) => {
            switch (options.name) {
              case 'default':
                return new Panel(options)
            }
          }
        })

        api.onDidAddPanel((e) => {
          // callback
          let pane = `#${e.params.id}`
          Shiny.initializeInputs($(pane))
          let inp = Shiny.shinyapp.$inputValues[id + "_panel_ids"]
          if (inp === undefined) {
            Shiny.setInputValue(id + "_panel_ids", [e.params.id], {priority: "event"});
          } else {
            inp.push(e.params.id);
            Shiny.setInputValue(id + "_panel_ids", inp, {priority: "event"});
          }
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
          window.dispatchEvent(new Event('resize'));
        })

        api.onDidMaximizedGroupChange((e) => {
          window.dispatchEvent(new Event('resize'));
        })

        // Init panels
        x.panels.map((panel) => {
          addPanel(api, panel, x, id);
        });

        

        if (HTMLWidgets.shinyMode) {
          Shiny.addCustomMessageHandler('add-panel', (m) => {
            addPanel(api, m, x, id)
          });

          Shiny.addCustomMessageHandler('rm-panel', (id) => {
            api.removePanel(api.getPanel(id));
          })
        }

      },

      resize: function (width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});


