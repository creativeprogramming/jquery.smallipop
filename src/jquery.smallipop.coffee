###!
Smallipop (10/15/2012)
Copyright (c) 2011-2012 Small Improvements (http://www.small-improvements.com)

Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.

@author Sebastian Helzle (sebastian@helzle.net)
###

(($) ->
  $.smallipop = sip =
    version: '0.3.0-alpha'
    defaults:
      contentAnimationSpeed: 150
      cssAnimations:
        enabled: false
        show: 'animated fadeIn'
        hide: 'animated fadeOut'
      funcEase: 'easeInOutQuad'
      handleInputs: true
      hideTrigger: false
      hideOnPopupClick: true
      hideOnTriggerClick: true
      horizontal: false
      infoClass: 'smallipopHint'
      invertAnimation: false
      popupOffset: 31
      popupYOffset: 0
      popupDistance: 20
      popupDelay: 100
      popupAnimationSpeed: 200
      preferredPosition: 'top' # bottom, top, left or right
      theme: 'default'
      touchSupport: true
      triggerAnimationSpeed: 150
      triggerOnClick: false
      onAfterHide: null
      onAfterShow: null
      onBeforeHide: null
      onBeforeShow: null
      windowPadding: 30 # Imaginary padding in viewport
    currentTour: null
    lastId: 1 # Counter for new smallipop id's
    lastScrollCheck: 0
    labels:
      prev: 'Prev'
      next: 'Next'
      close: 'Close'
      of: 'of'
    namespace: 'smallipop'
    popup: null
    templates:
      popup: '
        <div id="smallipop">
          <div class="sipContent"/>
          <div class="sipArrowBorder"/>
          <div class="sipArrow"/>
        </div>'
    tours: {}

    _hideSmallipop: (e) ->
      popup = sip.popup
      shownId = popup.data 'shown'
      target = if e?.target then $(e.target) else null

      # Show trigger if hidden before
      trigger = $ ".smallipop#{shownId}"
      triggerOptions = trigger.data('smallipop')?.options or sip.defaults

      # Do nothing if clicked and hide on click is disabled for this case
      return if target and trigger.length and e?.type is 'click' and \
        ((not triggerOptions.hideOnTriggerClick and target.is(trigger)) or \
        (not triggerOptions.hideOnPopupClick and popup.find(target).length))

      # Show trigger if it was hidden
      if shownId and triggerOptions.hideTrigger
        trigger.stop(true).fadeTo triggerOptions.triggerAnimationSpeed, 1

      direction = if triggerOptions.invertAnimation then -1 else 1
      xDistance = sip.popup.data('xDistance') * direction
      yDistance = sip.popup.data('yDistance') * direction

      popup
        .data
          hideDelayTimer: null
          beingShown: false

      if triggerOptions.cssAnimations.enabled
        popup
          .removeClass(triggerOptions.cssAnimations.show)
          .addClass(triggerOptions.cssAnimations.hide)
          .data('shown', '')

        if triggerOptions.onAfterHide
          window.setTimeout triggerOptions.onAfterHide, triggerOptions.popupAnimationSpeed
      else
        popup
          .stop(true)
          .animate
              top: "-=#{xDistance}px"
              left: "+=#{yDistance}px"
              opacity: 0
            , triggerOptions.popupAnimationSpeed, triggerOptions.funcEase, ->
              # Hide tip if not being shown in the meantime
              tip = $ @
              unless tip.data 'beingShown'
                tip
                  .css('display', 'none')
                  .data('shown', '')

              triggerOptions.onAfterHide?()

    _showSmallipop: (e) ->
      self = $ @
      triggerData = self.data 'smallipop'

      if sip.popup.data('shown') isnt triggerData.id \
        and not triggerData.type in ['checkbox', 'radio']
          e?.preventDefault()

      sip._triggerMouseover.call @

    onTouchDevice: ->
      Modernizr?.touch

    killTimers: ->
      popup = sip.popup
      hideTimer = popup.data 'hideDelayTimer'
      showTimer = popup.data 'showDelayTimer'
      clearTimeout(hideTimer) if hideTimer
      clearTimeout(showTimer) if showTimer

    refreshPosition: () ->
      popup = sip.popup
      shownId = popup.data 'shown'

      return unless shownId

      trigger = $ ".smallipop#{shownId}"
      options = trigger.data('smallipop').options

      # Remove alignment classes
      popup.removeClass (index, classNames) ->
        return (classNames.match(/sip\w+/g) or []).join ' '

      # Add theme class
      popup.addClass options.theme

      # Prepare some properties
      win = $ window
      xDistance = yDistance = options.popupDistance
      yOffset = options.popupYOffset

      # Get new dimensions
      offset = trigger.offset()

      popupH = popup.outerHeight()
      popupW = popup.outerWidth()
      popupCenter = popupW / 2

      winWidth = win.width()
      winHeight = win.height()
      windowPadding = options.windowPadding

      selfWidth = trigger.outerWidth()
      selfHeight = trigger.outerHeight()
      selfY = offset.top - win.scrollTop()

      popupOffsetLeft = offset.left + selfWidth / 2
      popupOffsetTop = offset.top - popupH + yOffset
      popupY = popupH + options.popupDistance - yOffset
      popupDistanceTop = selfY - popupY
      popupDistanceBottom = winHeight - selfY - selfHeight - popupY
      popupDistanceLeft = offset.left - popupW - options.popupOffset
      popupDistanceRight = winWidth - offset.left - selfWidth - popupW

      if options.horizontal
        xDistance = 0
        popupOffsetTop += selfHeight / 2 + popupH / 2
        if (options.preferredPosition is 'left' and popupDistanceLeft > windowPadding) or popupDistanceRight < windowPadding
          # Positioned left
          popup.addClass 'sipPositionedLeft'
          popupOffsetLeft = offset.left - popupW - options.popupOffset
          yDistance = -yDistance
        else
          # Positioned right
          popup.addClass 'sipPositionedRight'
          popupOffsetLeft = offset.left + selfWidth + options.popupOffset
      else
        yDistance = 0
        if popupOffsetLeft + popupCenter > winWidth - windowPadding
          # Aligned left
          popupOffsetLeft -= popupCenter * 2 - options.popupOffset
          popup.addClass 'sipAlignLeft'
        else if popupOffsetLeft - popupCenter < windowPadding
          # Aligned right
          popupOffsetLeft -= options.popupOffset
          popup.addClass 'sipAlignRight'
        else
          # Centered
          popupOffsetLeft -= popupCenter

        # Add class if positioned below
        if (options.preferredPosition is 'bottom' and popupDistanceBottom > windowPadding) or popupDistanceTop < windowPadding
          popupOffsetTop += popupH + selfHeight - 2 * yOffset
          xDistance = -xDistance
          yOffset = 0
          popup.addClass 'sipAlignBottom'

      # Hide trigger if defined
      if options.hideTrigger
        trigger
          .stop(true)
          .fadeTo(options.triggerAnimationSpeed, 0)

      # Animate to new position if refresh does no
      beingShown = popup.data 'beingShown'
      if not beingShown or options.cssAnimations.enabled
        popupOffsetTop -= xDistance
        popupOffsetLeft += yDistance
        xDistance = 0
        yDistance = 0

      popup
        .data
          xDistance: xDistance
          yDistance: yDistance


      popup.css
        top: popupOffsetTop
        left: popupOffsetLeft
        display: 'block'
        opacity: if beingShown and not options.cssAnimations.enabled then 0 else 1

      animationTarget =
        top: "-=#{xDistance}px"
        left: "+=#{yDistance}px"
        opacity: 1

      # Start fade in animation
      if options.cssAnimations.enabled
        popup.addClass options.cssAnimations.show

        if beingShown
          window.setTimeout ->
              popup.data 'beingShown', false
              options.onAfterShow? trigger
            , options.popupAnimationSpeed
      else
        popup
          .stop(true)
          .animate animationTarget, options.popupAnimationSpeed, options.funcEase, ->
            if beingShown
              popup.data 'beingShown', false
              options.onAfterShow? trigger

    _getTrigger: (id) ->
      $ ".smallipop#{id}"

    _showPopup: (trigger, content='') ->
      popup = sip.popup

      return unless popup.data 'triggerHovered'

      # Get smallipop options stored in trigger and popup
      triggerData = trigger.data 'smallipop'
      shownId = popup.data 'shown'

      # Show last trigger if not yet visible
      if shownId
        lastTrigger = sip._getTrigger shownId
        lastTriggerOpt = lastTrigger.data('smallipop').options or sip.defaults
        if lastTriggerOpt.hideTrigger
          lastTrigger
            .stop(true)
            .fadeTo(lastTriggerOpt.fadeSpeed, 1)

      # Update tip content and remove all classes
      popup.data
        beingShown: true
        shown: triggerData.id
      sip.popupContent.html content or triggerData.hint

      # Remove some css classes
      popup.removeClass() if triggerData.id isnt shownId

      sip.refreshPosition()

    _triggerMouseover: ->
      self = $ @
      popup = sip.popup

      id = self.data('smallipop')?.id
      shownId = popup.data 'shown'

      sip.killTimers()
      popup.data (if id then 'triggerHovered' else 'hovered'), true

      unless id
        self = sip._getTrigger shownId
        id = shownId

      # We should have a valid id and an active trigger by now
      return unless self.length

      options = self.data('smallipop').options
      options.onBeforeShow? self

      if shownId isnt id
        popup.data 'showDelayTimer', setTimeout ->
            sip._showPopup self
          , options.popupDelay

    _triggerMouseout: ->
      self = $ @
      id = self.data('smallipop')?.id

      popup = sip.popup
      popupData = popup.data()
      shownId = popupData.shown

      sip.killTimers()
      popup.data (if id then 'triggerHovered' else 'hovered'), false

      if id
        self.data('smallipop').options.onBeforeHide? self

      # Hide tip after a while
      unless popupData.hovered or popupData.triggerHovered
        popup.data 'hideDelayTimer', setTimeout(sip._hideSmallipop, 500)

    _onWindowResize: ->
      $.smallipop.refreshPosition()

    _onWindowClick: (e) ->
      popup = sip.popup
      target = $ e.target

      # Hide smallipop unless popup, a trigger is clicked or popup is being shown
      unless target.is(popup) or target.closest('.sipInitialized').length or popup.data('beingShown')
        sip._hideSmallipop e

    _onWindowScroll: (e) ->
      now = new Date().getTime()
      return if now - sip.lastScrollCheck < 300
      sip.lastScrollCheck = now
      $.smallipop.refreshPosition()

    setContent: (content) ->
      shownId = sip.popup.data 'shown'
      trigger = sip._getTrigger shownId
      options = trigger.data('smallipop')?.options

      if options
        sip.popupContent
          .stop(true)
          .fadeTo options.contentAnimationSpeed, 0, ->
            sip.popupContent
              .html(content)
              .fadeTo options.contentAnimationSpeed, 1
            sip.refreshPosition()

    _runTour: (trigger) ->
      triggerData = trigger.data 'smallipop'
      tourTitle = triggerData?.tourTitle

      return unless tourTitle and sip.tours[tourTitle]

      sip.currentTour = tourTitle

      # Sort tour elements before running by their index
      sip.tours[tourTitle].sort (a, b) ->
        a.index - b.index

      currentTourItems = sip.tours[tourTitle]
      for i in [0..currentTourItems.length - 1] when currentTourItems[i].id is triggerData.id
        return sip._tourShow tourTitle, i

    _tourShow: (title, index) ->
      currentTourItems = sip.tours[title]
      return unless currentTourItems

      trigger = currentTourItems[index].trigger
      triggerData = trigger.data 'smallipop'

      prevButton = if index > 0 then "<a href=\"#\" class=\"smallipop-tour-prev\">#{sip.labels.prev}</a>" else ''
      nextButton = if index < currentTourItems.length - 1 then "<a href=\"#\" class=\"smallipop-tour-next\">#{sip.labels.next}</a>" else ''
      closeButton = if index is currentTourItems.length - 1 then "<a href=\"#\" class=\"smallipop-tour-close\">#{sip.labels.close}</a>" else ''

      content = "
        <div class=\"smallipop-tour-content\">#{triggerData.hint}</div>
        <div class=\"smallipop-tour-footer\">
          <div class=\"smallipop-tour-progress\">
            #{index + 1} #{sip.labels.of} #{currentTourItems.length}
          </div>
          #{prevButton}
          #{nextButton}
          #{closeButton}
          <br style=\"clear:both;\"/>
        </div>"

      sip.killTimers()
      sip.popup.data 'triggerHovered', true
      sip._showPopup trigger, content

      # Scroll to trigger if it isn't visible
      sip._scrollUntilVisible trigger

    _scrollUntilVisible: (target) ->
      targetPosition = target.offset().top
      offset = targetPosition - $(document).scrollTop()
      windowHeight = $(window).height()

      if offset < windowHeight * .3 or offset > windowHeight * .7
        $('html, body').animate
            scrollTop: targetPosition - windowHeight / 2
          , 800, 'swing'

    _tourNext: (e) ->
      e?.preventDefault()
      currentTourItems = sip.tours[sip.currentTour]
      return unless currentTourItems

      # Get currently shown tour item
      shownId = sip.popup.data('shown') or currentTourItems[0].id

      for i in [0..currentTourItems.length - 2] when currentTourItems[i].id is shownId
        return sip._tourShow sip.currentTour, i + 1

    _tourPrev: (e) ->
      e?.preventDefault()
      currentTourItems = sip.tours[sip.currentTour]
      return unless currentTourItems

      # Get currently shown tour item
      shownId = sip.popup.data('shown') or currentTourItems[0].id

      for i in [1..currentTourItems.length - 1] when currentTourItems[i].id is shownId
        return sip._tourShow sip.currentTour, i - 1

    _tourClose: (e) ->
      e?.preventDefault()
      sip._hideSmallipop()

    _destroy: (instances) ->
      instances.each ->
        self = $ @
        data = self.data 'smallipop'
        if data
          self
            .unbind('.smallipop')
            .data('smallipop', {})
            .removeClass "smallipop sipInitialized smallipop#{data.id} #{data.options.theme}"

    _init: ->
      popup = sip.popup = $(sip.templates.popup)
        .css('opacity', 0)
        .data
          xDistance: 0
          yDistance: 0
        .bind
          'mouseover.smallipop': sip._triggerMouseover
          'mouseout.smallipop': sip._triggerMouseout

      sip.popupContent = popup.find '.sipContent'

      $('body').append popup

      # Add some binding to events in the popup
      popup
        .delegate('a', 'click.smallipop', sip._hideSmallipop)
        .delegate('.smallipop-tour-prev', 'click.smallipop', sip._tourPrev)
        .delegate('.smallipop-tour-next', 'click.smallipop', sip._tourNext)
        .delegate('.smallipop-tour-close', 'click.smallipop', sip._tourClose)

      $(document).bind 'click.smallipop touchend.smallipop', sip._onWindowClick

      $(window).bind
        'resize.smallipop': sip._onWindowResize
        'scroll.smallipop': sip._onWindowScroll

  ### Add default easing function for smallipop to jQuery if missing ###
  unless $.easing.easeInOutQuad
    $.easing.easeInOutQuad = (x, t, b, c, d) ->
      if ((t/=d/2) < 1) then c/2*t*t + b else -c/2 * ((--t)*(t-2) - 1) + b

  $.fn.smallipop = (options={}, hint='') ->
    # Handle direct method calls
    if typeof(options) is 'string'
      switch options.toLowerCase()
        when 'show' then sip._showSmallipop.call @first().get(0)
        when 'hide' then sip._hideSmallipop()
        when 'destroy' then sip._destroy @
        when 'tour' then sip._runTour @first()
      return @

    options = $.extend {}, sip.defaults, options

    # Check for enabled css animations and disable if modernizr is active says no
    if Modernizr?.cssanimations is false
      options.cssAnimations.enabled = false

    # Initialize smallipop on first call
    sip._init() unless sip.popup

    return @.each ->
      self = $ @
      tagName = self[0].tagName.toLowerCase()
      type = self.attr 'type'
      triggerData = self.data()

      # Get content for the popup
      objHint = hint or self.attr('title') or self.find(".#{options.infoClass}").html()

      # Initialize each trigger, create id and bind events
      if objHint and not self.hasClass 'sipInitialized'
        newId = sip.lastId++
        triggerOptions = $.extend true, {}, options
        triggerEvents = {}
        tourTitle = triggerData.smallipopTour
        isFormElement = triggerOptions.handleInputs and tagName in ['input', 'select', 'textarea']

        # Activate on blur events if used on inputs and disable hide on click
        if isFormElement
          # Don't hide when trigger is clicked and show when trigger is clicked
          triggerOptions.hideOnTriggerClick = false
          # triggerOptions.triggerOnClick = true
          triggerEvents['focus.smallipop'] = sip._triggerMouseover
          triggerEvents['blur.smallipop'] = sip._triggerMouseout
        else
          triggerEvents['mouseout.smallipop'] = sip._triggerMouseout

        # Check whether the trigger should activate smallipop by click or hover
        if triggerOptions.triggerOnClick or (triggerOptions.touchSupport and sip.onTouchDevice())
          triggerEvents['click.smallipop'] = sip._showSmallipop
        else
          triggerEvents['click.smallipop'] = sip._hideSmallipop
          triggerEvents['mouseover.smallipop'] = sip._triggerMouseover

        # Add to tours if tourTitle is set
        if tourTitle
          sip.tours[tourTitle] = [] unless sip.tours[tourTitle]
          sip.tours[tourTitle].push
            index: triggerData.smallipopIndex or 0
            id: newId
            trigger: self

          # Disable all trigger events
          triggerEvents = {}
          triggerOptions.hideOnTriggerClick = false
          triggerOptions.hideOnPopupClick = false

        # Store parameters for this trigger
        self
          .addClass("sipInitialized smallipop#{newId}")
          .attr('title', '') # Remove title to disable browser hint
          .data 'smallipop',
            id: newId
            hint: objHint
            options: triggerOptions
            tagName: tagName
            type: type
            tourTitle: tourTitle
          .bind triggerEvents

        # Hide popup when links contained in the trigger are clicked
        unless triggerOptions.hideOnTriggerClick
          self.delegate 'a', 'click.smallipop', sip._hideSmallipop
)(jQuery)
