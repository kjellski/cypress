_ = require("lodash")
Promise = require("bluebird")

{ delay } = require("./utils")
$Log = require("../../../cypress/log")
$utils = require("../../../cypress/utils")

module.exports = (Commands, Cypress, cy, state, config) ->
  Commands.addAll({ prevSubject: "dom" }, {
    submit: (subject, options = {}) ->
      _.defaults options,
        log: true
        $el: subject

      cy.ensureDom(options.$el)

      ## changing this to a promise .map() causes submit events
      ## to break when they need to be triggered synchronously
      ## like with type {enter}.  either convert type to a promise
      ## to just create a synchronous submit function
      form = options.$el.get(0)

      if options.log
        options._log = Cypress.log
          $el: options.$el
          consoleProps: ->
            "Applied To": $utils.getDomElements(options.$el)
            Elements: options.$el.length

        options._log.snapshot("before", {next: "after"})

      if not options.$el.is("form")
        node = $utils.stringifyElement(options.$el)
        word = $utils.plural(options.$el, "contains", "is")
        $utils.throwErrByPath("submit.not_on_form", {
          onFail: options._log
          args: { node, word }
        })

      if (num = options.$el.length) and num > 1
        $utils.throwErrByPath("submit.multiple_forms", {
          onFail: options._log
          args: { num }
        })

      ## calling the native submit method will not actually trigger
      ## a submit event, so we need to dispatch this manually so
      ## native event listeners and jquery can bind to it
      submit = new Event("submit", {bubbles: true, cancelable: true})
      !!dispatched = form.dispatchEvent(submit)

      ## now we need to check to see if we should actually submit
      ## the form!
      ## dont submit the form if our dispatched event was cancelled (false)
      form.submit() if dispatched

      cy.timeout(delay, true)

      Promise
      .delay(delay, "submit")
      .then =>
        do verifyAssertions = =>
          cy.verifyUpcomingAssertions(options.$el, options, {
            onRetry: verifyAssertions
          })

    fill: (subject, obj, options = {}) ->
      $utils.throwErrByPath "fill.invalid_1st_arg" if not _.isObject(obj)

  })
