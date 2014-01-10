CocoClass = require 'lib/CocoClass'

module.exports = class Pickup extends CocoClass
  # @ITEM = "thaing"  # A speech bubble from a script
  # @STYLE_SAY = "say"  # A piece of text generated from the world
  # @STYLE_NAME = "name"  # A name like Scott set up for the Wizard
  # We might want to combine 'say' and 'name'; they're very similar
  # Nick designed 'say' based off of Scott's 'name' back when they were using two systems

  subscriptions: {}

  constructor: (options) ->
    super()
    options ?= {}
    @sprite = options.sprite
    @camera = options.camera
    @layer = options.layer
    console.error @toString(), "needs a sprite." unless @sprite
    console.error @toString(), "needs a camera." unless @camera
    console.error @toString(), "needs a layer." unless @layer

  destroy: ->
    @setPickup null
    super()

  toString: -> "<pickup for #{@sprite?.thang?.id ? 'None'}: #{@text?.substring(0, 10) ? ''}>"

  setPickup: () ->
    # Returns whether an update was actually performed
    return true if @pickup
    @text="YOLO"
    @pickup = true
    @build()
    true

  build: ->
    
    @layer.removeChild @background if @background
    @layer.removeChild @pickup if @pickup
    return unless @pickup  # null or '' should both be skipped
    console.log("Buildin!")
    o = @buildPickupOptions()
    @layer.addChild @pickup = @buildPickup o
    @layer.addChild @background = @buildBackground o
    @layer.updateLayerOrder()

  update: ->
    console.log("Updatin.")
    return unless @pickup
    offset = @sprite.getOffset('aboveHead')
    offset ?= x: 0, y: 0  # temp (if not CocoSprite)
    @pickup.x = @background.x = @sprite.displayObject.x + offset.x
    @pickup.y = @background.y = @sprite.displayObject.y + offset.y
    null

  buildPickupOptions: ->
    o = {}
    st = {item: 'I', name: 'N'}[@style]
    o.marginX = {I: 5, N: 3}[st]
    o.marginY = {I: 6, N: 3}[st]
    o.shadow = {D: false, N: true}[st]
    o.fontSize = {D: 25, N: 14}[st]
    fontFamily = {D: "Arial", N: "Arial"}[st]
    o.fontDescriptor = "#{o.fontSize}px #{fontFamily}"
    o.fontColor = {D: "#000", N: "#00a"}[st]
    o.backgroundFillColor = {D: "white", N: "rgba(255, 255, 255, 0.5)"}[st]
    o.backgroundStrokeColor = {D: "black", N: "rgba(0, 0, 0, 0.0)"}[st]
    o.backgroundStrokeStyle = {D: 2, N: 1}[st]
    o.backgroundBorderRadius = {D: 10, N: 3}[st]
    o.layerPriority = {D: 10, N: 5}[st]
    maxWidth = {D: 300, N: 180}[st]
    maxWidth = Math.max @camera.canvasWidth / 2 - 100, maxWidth  # Does this do anything?
    maxLength = {D: 100, N: 30}[st]
    multiline = @addNewLinesToText _.string.prune(@text, maxLength), o.fontDescriptor, maxWidth
    o.text = multiline.text
    o.textWidth = o.text.textWidth
    o

  buildPickup: (o) ->
    pickup = new createjs.Text o.text, o.fontDescriptor, o.fontColor
    pickup.lineHeight = o.fontSize + 2
    pickup.x = o.marginX
    pickup.y = o.marginY
    pickup.shadow = new createjs.Shadow "#FFF", 1, 1, 0 if o.shadow
    pickup.layerPriority = o.layerPriority
    pickup.name = "Sprite pickup - #{@style}"
    o.textHeight = pickup.getMeasuredHeight()
    o.pickup = pickup
    pickup

  buildBackground: (o) ->
    w = o.textWidth + 2 * o.marginX
    h = o.textHeight + 2 * o.marginY + 1  # Is this +1 needed?

    background = new createjs.Shape()
    background.name = "Sprite pickup Background - #{@style}"
    g = background.graphics
    g.beginFill o.backgroundFillColor
    g.beginStroke o.backgroundStrokeColor
    g.setStrokeStyle o.backgroundStrokeStyle

    # Just draw a rounded rectangle
    background.regX = w / 2
    background.regY = h + 2  # Just above health bar, say
    g.drawRoundRect(o.pickup.x - o.marginX, o.pickup.y - o.marginY, w, h, o.backgroundBorderRadius)

    o.pickup.regX = background.regX - o.marginX
    o.pickup.regY = background.regY - o.marginY

    g.endStroke()
    g.endFill()
    background.layerPriority = o.layerPriority - 1
    background

  addNewLinesToText: (originalText, fontDescriptor, maxWidth=400) ->
    rows = []
    row = []
    words = _.string.words originalText
    textWidth = 0
    for word in words
      row.push(word)
      text = new createjs.Text(_.string.join(' ', row...), fontDescriptor, "#000")
      width = text.getMeasuredWidth()
      if width > maxWidth
        if row.length is 1 # one long word, truncate it
          row[0] = _.string.truncate(row[0], 40)
          rows.push(row)
          row = []
        else
          row.pop()
          rows.push(row)
          row = [word]
      else
        textWidth = Math.max(textWidth, width)
    rows.push(row)
    for row, i in rows
      rows[i] = _.string.join(" ", row...)
    text: _.string.join("\n", rows...), textWidth: textWidth
