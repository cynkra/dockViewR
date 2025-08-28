import 'widgets';
import 'dockview-core/dist/styles/dockview.css'
import { createDockview } from "dockview-core";

import { Panel, RightHeader, LeftHeader, CustomTab, DefaultTab } from '../modules/components'
import { matchTheme, addPanel, movePanel, saveDock, moveGroup, moveGroup2 } from '../modules/utils';

HTMLWidgets.widget({

  name: 'dockview',

  type: 'output',

  factory: function (el, width, height) {

    let api;

    return {

      renderValue: function (x, id = el.id) {

        // Instantiate dockView
        api = createDockview(document.getElementById(id), {
          theme: matchTheme(x.theme),
          createRightHeaderActionComponent: (options) => {
            return new RightHeader(options)
          },
          createLeftHeaderActionComponent: (options) => {
            options._params.params.addTab = x.addTab;
            return new LeftHeader(options)
          },
          createComponent: (options) => {
            switch (options.name) {
              case 'default':
                return new Panel(options)
            }
          },
          createTabComponent: (options) => {
            switch (options.name) {
              case 'manual':
                return new DefaultTab();
              case 'custom':
                return new CustomTab();
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
              let pane = `#${id}-${panel.id}`;
              Shiny.initializeInputs($(pane));
              Shiny.bindAll($(pane));
            })
          }
        })

        api.onDidMaximizedGroupChange((e) => {
          window.dispatchEvent(new Event('resize'));
        })

        api.onDidAddPanel((e) => {
          if (HTMLWidgets.shinyMode) {
            Shiny.setInputValue(id + '_added-panel', e.id, { priority: 'event' });
          }
        })

        api.onDidRemovePanel((e) => {
          if (HTMLWidgets.shinyMode) {
            Shiny.setInputValue(id + '_removed-panel', e.id, { priority: 'event' });
          }
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

          Shiny.addCustomMessageHandler(el.id + '_select-panel', (m) => {
            api.getPanel(m.id).api.setActive();
          })

          // set renderer
          Shiny.addCustomMessageHandler(el.id + '_set-panel-renderer', (m) => {
            api.getPanel(m.id).api.setRenderer(m.renderer);
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
          Shiny.addCustomMessageHandler(el.id + '_move-group2', (m) => {
            moveGroup2(m, api)
          })

          Shiny.addCustomMessageHandler(el.id + '_move-group', (m) => {
            moveGroup(m, api)
          })

          Shiny.addCustomMessageHandler(el.id + '_update-options', (m) => {
            if (m.hasOwnProperty('theme')) {
              m.theme = matchTheme(m.theme);
            }
            api.updateOptions(m);
          })
        }

      },
      getWidget: function () {
        return api;
      },
      resize: function (width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
