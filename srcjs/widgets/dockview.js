import 'widgets';
import 'dockview-core/dist/styles/dockview.css';
import { setDockViewCallbacks } from '../modules/callbacks';
import { saveDock } from '../modules/proxy';
import { setShinyHandlers } from '../modules/handlers';
import { instantiateDock, initDockPanels } from '../modules/dock';

HTMLWidgets.widget({

  name: 'dockview',

  type: 'output',

  factory: function (el, width, height) {

    let api;

    return {

      renderValue: function (x, id = el.id) {

        // Instantiate dockView
        api = instantiateDock(id, x);

        // Init state
        saveDock(id, api)

        // Set API callbacks: onAddPanel, ...
        setDockViewCallbacks(id, api);

        // Init panels
        initDockPanels(x, api);

        // Set any Shiny handlers for proxy operations
        if (HTMLWidgets.shinyMode) {
          setShinyHandlers(id, x.mode, api);
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
