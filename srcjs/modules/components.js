class Panel {
  get element() {
    return this._element
  }

  constructor() {
    this._element = document.createElement('div')
  }

  init(config) {
    this._element.id = config.params.id
    this._element.innerHTML = config.params.content.html
    this._element.className = 'dockview-panel'
    this._element.style = 'margin: 10px; padding: 10px;'
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
    this._element.innerHTML = '<i class="fas fa-expand" role="presentation" aria-label="plus icon"></i>'
    this._element.addEventListener('click', (e) => {
      if (!config.api.isMaximized()) {
        $(e.target).removeClass('fa-expand').addClass('fa-compress')
        config.api.maximize()
      } else {
        config.api.exitMaximized()
        $(e.target).removeClass('fa-compress').addClass('fa-expand')
      }
    });
  }
  dispose() {
    // Necessary to avoid a JS error when moving a panel
    // inside another one to get nested tabs
  }
}

export { RightHeader, Panel };