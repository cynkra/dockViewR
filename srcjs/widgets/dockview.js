import 'widgets';
import 'dockview-core/dist/styles/dockview.css';
import { setDockViewCallbacks } from '../modules/callbacks';
import { saveDock, withServerDriven } from '../modules/proxy';
import { setShinyHandlers } from '../modules/handlers';
import { instantiateDock, initDockPanels } from '../modules/dock';

HTMLWidgets.widget({

  name: 'dockview',

  type: 'output',

  factory: function (el, width, height) {

    let api;
    let teardown;

    return {

      renderValue: function (x, id = el.id) {

        // A reactive renderDockView re-renders in place; tear down the previous
        // dock and its container listeners before rebuilding, or they accumulate
        // and re-emit superseded state.
        if (teardown) teardown();
        if (api) api.dispose();

        // Instantiate dockView
        api = instantiateDock(id, x);

        // The initial layout (and the empty grid before its panels land) is
        // produced by the server, not a user gesture, so its `_state` is
        // reported as server-initiated -- same as a later proxy push.
        withServerDriven(id, () => {
          // Init state
          saveDock(id, api)

          // Set API callbacks: onAddPanel, ...
          teardown = setDockViewCallbacks(id, api);

          // Init panels
          initDockPanels(x, api);
        });

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
