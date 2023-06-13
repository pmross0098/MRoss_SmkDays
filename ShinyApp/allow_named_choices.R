#' Allow named choices
#'

#' @param inputId  id of input widget
#' @param update_function  to handle updates to widget
#' @param input
#' @param session
#' @param init_choices  named choices to initialize extended widget
#' @param init_selected named select  to initialize extended widget
#' @param ...    any other param to do initial update, probably not used
#'
#' @return a list of functions:
#' read() reads a named input from widget
#' update() update widget with named choices og selection (by name)
#'
#' @export
#'
#' @examples
allow_named_choices <- function(
    inputId,
    update_function,
    input,
    session,
    init_choices,
    init_selected = NULL,
    ...
){

  #named choices is stored here
  rv_named_choices <- reactiveVal()

  #define function for updating named choices
  writer_fun <- function(
    selected      = NULL,
    choices       = NULL,
    ...
  ){
    #store choices and names of choices
    if(!is.null(choices)) rv_named_choices(choices)

    #update, send only names of choices to client
    update_function(
      session       = session,
      inputId       = inputId,
      selected      = names(selected),
      choices       = names(choices),
      ...
    )
    invisible(choices)
  }


  #define reactive reading stored choices by client selected names
  r_reader = reactive({
    rv_named_choices()[input[[inputId]]]
  })



  #update now, to make sure client side choices match server side
  writer_fun(
    selected = init_selected,
    choices  = init_choices,
    ...
  )

  #return 'update' and 'read' functions in a list
  list(
    update = writer_fun,
    read   = r_reader
  )
}
