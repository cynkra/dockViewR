import { addPanel, defaultPanel } from './utils';
class Panel {
  get element() {
    return this._element
  }

  constructor() {
    this._element = document.createElement('div')
  }

  init(config) {
    let dockId = config.containerApi.component.gridview.element.closest('.dockview').attributes.id.textContent;
    this._element.id = dockId + '-' + config.api.id;
    this._element.innerHTML = config.params.content.html
    this._element.className = 'dockview-panel'
    this._element.style = 'height: 100%; margin: 10px; padding: 10px; overflow: auto;'
  }
}

// Tab without remove button
class CustomTab {
  constructor() {
    this._element = document.createElement('div');

    this.e1 = document.createElement('div');
    this.e2 = document.createElement('span');

    this.element.append(this.e1, this.e2);
  }

  get element() {
    return this._element;
  }

  init(config) {
    this.e1.textContent = config.title;
  }
}

class RightHeader {
  get element() {
    return this._element
  }

  constructor() {
    this._element = document.createElement('div')
  }

  init(config) {
    this._element.style = 'height: 100%; padding: 8px'
    this._element.innerHTML = '<i class="fas fa-expand" role="presentation" aria-label="expand icon"></i>'
    this._element.addEventListener('click', (e) => {
      if (!config.api.isMaximized()) {
        e.target.classList.remove('fa-expand');
        e.target.classList.add('fa-compress');
        config.api.maximize();
      } else {
        config.api.exitMaximized();
        e.target.classList.remove('fa-compress');
        e.target.classList.add('fa-expand');
      }
    });
  }
  dispose() {
    // Necessary to avoid a JS error when moving a panel
    // inside another one to get nested tabs
  }
}

class LeftHeader {
  get element() {
    return this._element
  }

  constructor() {
    this._element = document.createElement('div')
  }

  init(config) {
    // If addTab is false, we do not need to render this component
    if (!config.group._params.params.addTab.enable) return null;
    this._element.style = 'height: 100%; padding: 8px'
    this._element.innerHTML = '<i class="fas fa-plus" role="presentation" aria-label="plus icon"></i>'
    this._element.addEventListener('click', (e) => {
      config.group._params.params.addTab.callback(config);
    });
  }
  dispose() {
    // Necessary to avoid a JS error when moving a panel
    // inside another one to get nested tabs
  }
}

export { RightHeader, LeftHeader, Panel, CustomTab };