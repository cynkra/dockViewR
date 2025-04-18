import 'widgets';
import 'dockview-core/dist/styles/dockview.css'
import { createDockview } from "dockview-core";

import { Panel, RightHeader, LeftHeader } from '../modules/components'
import { matchTheme, addPanel, movePanel, saveDock } from '../modules/utils';

HTMLWidgets.widget({

  name: 'dockview',

  type: 'output',

  factory: function (el, width, height) {

    // TODO: define shared variables for this instance

    return {

      renderValue: function (x, id = el.id) {

        // Instantiate dockView
        const api = createDockview(document.getElementById(id), {
          theme: matchTheme(x.theme),
          createRightHeaderActionComponent: (options) => {
            return new RightHeader(options)
          },
          createLeftHeaderActionComponent: (options) => {
            return new LeftHeader(options)
          },
          createComponent: (options) => {
            switch (options.name) {
              case 'default':
                return new Panel(options)
            }
          }
        })

        // Resize panel content on layout change
        // (useful so that plots or widgets resize correctly)
        // Also update the dock state.
        api.onDidLayoutChange(() => {
          window.dispatchEvent(new Event('resize'));
          if (HTMLWidgets.shinyMode) {
            saveDock(id, api)
            api.panels.map((panel) => {
              let pane = `#${panel.id}`;
              Shiny.initializeInputs($(pane));
              Shiny.bindAll($(pane));
            })
          }
        })

        api.onDidMaximizedGroupChange((e) => {
          window.dispatchEvent(new Event('resize'));
        })

        // Init panels
        x.panels.map((panel) => {
          addPanel(panel, api);
        });

        if (HTMLWidgets.shinyMode) {
          Shiny.addCustomMessageHandler(el.id + '_add-panel', (panel) => {
            addPanel(panel, api);
          });

          Shiny.addCustomMessageHandler(el.id + '_rm-panel', (id) => {
            api.removePanel(api.getPanel(id));
          })

          Shiny.addCustomMessageHandler(el.id + '_move-panel', (m) => {
            movePanel(m, api)
          })

          // Force save dock
          Shiny.addCustomMessageHandler(el.id + '_save-state', (m) => {
            saveDock(id, api)
          })

          // Restore layout
          Shiny.addCustomMessageHandler(el.id + '_restore-state', (m) => {
            // Avoid duplicate input/output warning when rebinding
            Shiny.unbindAll($(`#${id} .dockview-panel`))
            api.fromJSON(m)
          })
        }

      },

      resize: function (width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
