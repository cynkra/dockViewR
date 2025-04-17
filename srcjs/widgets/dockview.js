import 'widgets';
import 'dockview-core/dist/styles/dockview.css'
import { createDockview } from "dockview-core";

import { Panel, RightHeader, LeftHeader } from '../modules/components'
import { matchTheme, addPanel, saveDock } from '../modules/utils';

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
        api.onDidLayoutChange((e) => {
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

        api.onDidAddPanel((e) => {
          if (HTMLWidgets.shinyMode) {
            let pane = `#${e.params.id}`;
            Shiny.initializeInputs($(pane));
          }
        })

        // Bind input/output
        api.onDidActivePanelChange((e) => {
          if (HTMLWidgets.shinyMode) {
            let pane = `#${e.params.id}`
            Shiny.bindAll($(pane))
          }
        })

        if (HTMLWidgets.shinyMode) {
          Shiny.addCustomMessageHandler(el.id + '_add-panel', (panel) => {
            addPanel(api, panel);
          });

          Shiny.addCustomMessageHandler(el.id + '_rm-panel', (id) => {
            api.removePanel(api.getPanel(id));
          })

          Shiny.addCustomMessageHandler(el.id + '_move-panel', (m) => {
            let panel = api.getPanel(`${m.id}`);
            // Move relative to another group
            if (m.options.group !== undefined) {
              let groupTarget = api.getPanel(`${m.options.group}`)
              panel.api.moveTo({
                group: groupTarget.api.group,
                position: m.options.position,
              })
              return null;
            }
            // Moce panel inside the same group using 'index' only
            panel.api.moveTo(m.options);
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
