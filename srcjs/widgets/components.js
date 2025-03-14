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
    this._element.style = 'height: 100%; padding: 0px 4px'
    this._element.innerHTML = '<i class="fas fa-plus" role="presentation" aria-label="plus icon"></i>'
    this._element.addEventListener('click', (e) => {
      if (!config.api.isMaximized()) {
        $(e.target).removeClass('fa-plus').addClass('fa-minus')
        config.api.maximize()
      } else {
        config.api.exitMaximized()
        $(e.target).removeClass('fa-minus').addClass('fa-plus')
      }
    });
  }
}

export { RightHeader, Panel };