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

        // This event must be registered before adding the panels
        api.onDidAddPanel((e) => {
          if (HTMLWidgets.shinyMode) {
            let pane = `#${e.params.id}`;
            Shiny.initializeInputs($(pane));
          }
        })

        // This event must be registered before adding the panels.
        // Bind input/output
        api.onDidActivePanelChange((e) => {
          if (HTMLWidgets.shinyMode) {
            let pane = `#${e.params.id}`
            Shiny.bindAll($(pane))
          }
        })

        // Resize panel content on layout change
        // (useful so that plots or widgets resize correctly)
        // Also update the dock state.
        api.onDidLayoutChange(() => {
          window.dispatchEvent(new Event('resize'));
          if (HTMLWidgets.shinyMode) saveDock(id, api)
        })

        api.onDidMaximizedGroupChange((e) => {
          window.dispatchEvent(new Event('resize'));
        })

        // Init panels
        x.panels.map((panel) => {
          addPanel(api, panel);
        });

        if (HTMLWidgets.shinyMode) {
          Shiny.addCustomMessageHandler(el.id + '_add-panel', (panel) => {
            addPanel(api, panel);
          });

          Shiny.addCustomMessageHandler(el.id + '_rm-panel', (id) => {
            api.removePanel(api.getPanel(id));
          })

          Shiny.addCustomMessageHandler(el.id + '_move-panel', (m) => {
            movePanel(m, api)
          })

          // Force save dock
          Shiny.addCustomMessageHandler(el.id + '_save-dock', (m) => {
            saveDock(id, api)
          })

          // Restore layout
          Shiny.addCustomMessageHandler(el.id + '_restore-dock', (m) => {
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
