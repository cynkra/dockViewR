% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{list_panels}
\alias{list_panels}
\title{list all available panels}
\usage{
list_panels(proxy, session = shiny::getDefaultReactiveDomain())
}
\arguments{
\item{proxy}{Result of \code{\link[=dock_view]{dock_view()}} or a character with the ID of the dockview.}

\item{session}{shiny session object.}
}
\description{
list all available panels
}
\note{
Only works with server side functions like \link{add_panel}. Don't call it
from the UI.
}
