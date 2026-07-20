import 'widgets';
import 'dockview-core/dist/styles/dockview.css';
import { setDockViewCallbacks } from '../modules/callbacks';
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

        // Wire callbacks (which arm the ResizeObserver gate), then add the
        // initial panels. `_state` stays gated until the ResizeObserver reports
        // real geometry, so the empty grid and the pre-size structure never reach
        // the consumer -- only the settled layout does.
        teardown = setDockViewCallbacks(id, api);
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
