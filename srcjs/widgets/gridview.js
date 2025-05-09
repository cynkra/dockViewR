import 'widgets';
import 'dockview-core/dist/styles/dockview.css'
import { createGridview, GridviewPanel, Orientation } from "dockview-core";
import { matchTheme } from '../modules/utils';

class TestGridview extends GridviewPanel {
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
    let gridId = config.accessor.gridview.element.closest('.gridview').attributes.id.textContent;
    this._element.id = gridId + '-' + config.params.id;
    this._element.innerHTML = config.params.content.html
    this._element.className = 'dockview-panel'
    this._element.style = 'height: 100%; margin: 10px; padding: 10px; overflow: auto;'
  }
}

const addPanel = (panel, api) => {
  let internals = {
    component: 'default',
    params: {
      // For gridview we need to explicitly pass the id as it can't vbe retrieved otherwise
      // from the accessor component.
      id: panel.id,
      content: panel.content
    }
  }
  let props = { ...panel, ...internals }
  return (api.addPanel(props))
}

HTMLWidgets.widget({

  name: 'gridview',

  type: 'output',

  factory: function (el, width, height) {

    // TODO: define shared variables for this instance
    let api;

    return {

      renderValue: function (x, id = el.id) {
        // TODO: code to render the widget, e.g.
        let gridOrientation;
        if (x.layout.orientation === 'horizontal') {
          gridOrientation = Orientation.HORIZONTAL;
        } else {
          gridOrientation = Orientation.VERTICAL;
        }
        const { className } = matchTheme(x.theme);
        api = createGridview(document.getElementById(id), {
          orientation: gridOrientation,
          proportionalLayout: x.layout.proportionalLayout,
          className: className,
          hideBorders: x.hideBorders,
          disableAutoResizing: x.disableAutoResizing,
          createComponent: (options) => {
            switch (options.name) {
              case 'default':
                return new TestGridview(options)
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
