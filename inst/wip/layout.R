side_by_side_layout <- function() {
  list(
    grid = list(
      root = list(
        type = "branch",
        data = list(
          list(
            type = "leaf",
            data = list(
              views = list("a"),
              activeView = "a",
              id = "1"
            ),
            size = 95
          ),
          list(
            type = "leaf",
            data = list(
              views = list("b"),
              activeView = "b",
              id = "2"
            ),
            size = 95
          )
        ),
        size = 0
      ),
      width = 0,
      height = 0,
      orientation = "HORIZONTAL"
    ),
    panels = structure(
      list(
        list(
          id = "a",
          contentComponent = "default",
          tabComponent = "custom",
          params = list(
            content = list(
              html = "Panel A"
            ),
            style = "padding:10px;overflow:auto;height:100%;margin:10px;"
          ),
          title = "A"
        ),
        list(
          id = "b",
          contentComponent = "default",
          tabComponent = "custom",
          params = list(
            content = list(
              html = "Panel B"
            ),
            style = "padding:10px;overflow:auto;height:100%;margin:10px;"
          ),
          title = "B"
        )
      ),
      names = c("a", "b")
    ),
    activeGroup = "2"
  )
}

tabbed_layout <- function() {
  list(
    grid = list(
      root = list(
        type = "branch",
        data = list(
          list(
            type = "leaf",
            data = list(
              views = list("a", "b"),
              activeView = "b",
              id = "1"
            ),
            size = 100
          )
        ),
        size = 0
      ),
      width = 0,
      height = 0,
      orientation = "HORIZONTAL"
    ),
    panels = structure(
      list(
        list(
          id = "a",
          contentComponent = "default",
          tabComponent = "custom",
          params = list(
            content = list(
              html = "Panel A"
            ),
            style = "padding:10px;overflow:auto;height:100%;margin:10px;"
          ),
          title = "A"
        ),
        list(
          id = "b",
          contentComponent = "default",
          tabComponent = "custom",
          params = list(
            content = list(
              html = "Panel B"
            ),
            style = "padding:10px;overflow:auto;height:100%;margin:10px;"
          ),
          title = "B"
        )
      ),
      names = c("a", "b")
    ),
    activeGroup = "1"
  )
}

nested_layout <- function() {
  list(
    grid = list(
      root = list(
        type = "branch",
        data = list(
          list(
            type = "branch",
            data = list(
              list(
                type = "leaf",
                data = list(
                  views = list("a"),
                  activeView = "a",
                  id = "1"
                ),
                size = 95
              ),
              list(
                type = "leaf",
                data = list(
                  views = list("c"),
                  activeView = "c",
                  id = "3"
                ),
                size = 95
              )
            ),
            size = -5
          ),
          list(
            type = "leaf",
            data = list(
              views = list("b"),
              activeView = "b",
              id = "2"
            ),
            size = 95
          )
        ),
        size = 0
      ),
      width = 0,
      height = 0,
      orientation = "HORIZONTAL"
    ),
    panels = structure(
      list(
        list(
          id = "a",
          contentComponent = "default",
          tabComponent = "custom",
          params = list(
            content = list(
              html = "Panel A"
            ),
            style = "padding:10px;overflow:auto;height:100%;margin:10px;"
          ),
          title = "A"
        ),
        list(
          id = "b",
          contentComponent = "default",
          tabComponent = "custom",
          params = list(
            content = list(
              html = "Panel B"
            ),
            style = "padding:10px;overflow:auto;height:100%;margin:10px;"
          ),
          title = "B"
        ),
        list(
          id = "c",
          contentComponent = "default",
          tabComponent = "custom",
          params = list(
            content = list(
              html = "Panel C"
            ),
            style = "padding:10px;overflow:auto;height:100%;margin:10px;"
          ),
          title = "C"
        )
      ),
      names = c("a", "b", "c")
    ),
    activeGroup = "3"
  )
}
