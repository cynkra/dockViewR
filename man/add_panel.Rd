% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/add_panel.R
\name{add_panel}
\alias{add_panel}
\title{Add Panel dynamically}
\usage{
add_panel(dock_id, panel, ..., session = getDefaultReactiveDomain())
}
\arguments{
\item{dock_id}{Dock unique id. When using modules the namespace is
automatically added.}

\item{panel}{A panel object. See \link{panel} for the different parameters.}

\item{...}{Other options passed to the API. Not used yet.}

\item{session}{shiny session object.
See \url{https://dockview.dev/docs/api/dockview/panelApi/}.}
}
\value{
This function is called for its side effect.
It sends a message to JavaScript through the current websocket connection,
leveraging the shiny session object.
}
\description{
Add Panel dynamically
}
\seealso{
\code{\link[=panel]{panel()}}
}
