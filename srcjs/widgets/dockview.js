import 'widgets';
import 'dockview-core/dist/styles/dockview.css'
import { createDockview } from "dockview-core";

import { Panel, RightHeader, LeftHeader } from '../modules/components'
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

        api.onDidAddPanel((e) => {
          let pane = `#${e.params.id}`;
          Shiny.initializeInputs($(pane));
          let inp = Shiny.shinyapp.$inputValues[id + "_panel_ids"];
          if (inp === undefined) {
            Shiny.setInputValue(id + "_panel_ids", [e.params.id], { priority: "event" });
          } else {
            inp.push(e.params.id);
            Shiny.setInputValue(id + "_panel_ids", inp, { priority: "event" });
          }
        })

        api.onDidRemovePanel((e) => {
          let inp = Shiny.shinyapp.$inputValues[id + "_panel_ids"];
          inp.splice(inp.indexOf(e.id), 1);
          Shiny.setInputValue(id + "_panel_ids", inp, { priority: "event" });
        })

        // Bind input/output
        api.onDidActivePanelChange((e) => {
          let pane = `#${e.params.id}`
          Shiny.bindAll($(pane))
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
          Shiny.addCustomMessageHandler(el.id + '_move-group2', (m) => {
            let panel = api.getPanel(`${m.id}`);
            // Move relative to another group
            let groupTarget = api.getPanel(`${m.options.destination}`);
            panel.group.api.moveTo({
              group: groupTarget.api.destination,
              position: m.options.position
            });
            return null;
          })
        }

      },

      resize: function (width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
