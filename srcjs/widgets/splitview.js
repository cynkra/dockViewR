import 'widgets';
import 'dockview-core/dist/styles/dockview.css'
import { createSplitview, SplitviewPanel, Orientation } from "dockview-core";
import { matchTheme } from '../modules/utils';

class TestSplitview extends SplitviewPanel {
  constructor(config) {
    super(config.id, config.componentName);
    this.api.initialize(this);
  }

  //getComponent() {
  //  return {
  //    update: (params) => {
  //      //
  //    },
  //    dispose: () => {
  //      //
  //    },
  //  };
  //}
  init(config) {
    let splitId = config.accessor.splitview.element.closest('.splitview').attributes.id.textContent;
    this._element.id = splitId + '-' + config.params.id;
    this._element.innerHTML = config.params.content.html
    this._element.className = 'dockview-panel'
    this._element.style = 'height: 100%; margin: 10px; padding: 10px; overflow: auto;'
  }
}

const addPanel = (panel, api) => {
  let internals = {
    component: 'default',
    params: {
      // For splitview we need to explicitly pass the id as it can't vbe retrieved otherwise
      // from the accessor component.
      id: panel.id,
      content: panel.content
    }
  }
  let props = { ...panel, ...internals }
  return (api.addPanel(props))
}

HTMLWidgets.widget({

  name: 'splitview',

  type: 'output',

  factory: function (el, width, height) {

    // TODO: define shared variables for this instance
    let api;

    return {

      renderValue: function (x, id = el.id) {
        // TODO: code to render the widget, e.g.
        let splitOrientation;
        if (x.layout.orientation === 'horizontal') {
          splitOrientation = Orientation.HORIZONTAL;
        } else {
          splitOrientation = Orientation.VERTICAL;
        }
        const { className } = matchTheme(x.theme);
        api = createSplitview(document.getElementById(id), {
          orientation: splitOrientation,
          proportionalLayout: x.layout.proportionalLayout,
          className: className,
          hideBorders: x.hideBorders,
          disableAutoResizing: x.disableAutoResizing,
          createComponent: (options) => {
            switch (options.name) {
              case 'default':
                return new TestSplitview(options)
            }
          }
        })

        // Important to see something.
        api.layout(x.layout.width, x.layout.height);

        api.onDidLayoutChange(() => {
          window.dispatchEvent(new Event('resize'));
          if (HTMLWidgets.shinyMode) {
            api.panels.map((panel) => {
              let pane = `#${id}-${panel.id}`;
              Shiny.initializeInputs($(pane));
              Shiny.bindAll($(pane));
            })
          }
        })

        // Init panels
        x.panels.map((panel) => {
          addPanel(panel, api);
        });

      },

      resize: function (width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});