window.addEventListener "load", ->
  canvas = document.querySelector 'canvas'
  histCanvas = document.querySelector '#histogram-canvas'
  context = canvas.getContext '2d'
  histContext = histCanvas.getContext '2d'

  getPixel = (imageData,x,y) ->
    index = (x + y * imageData.width) * 4
    r: imageData.data[index+0]
    g: imageData.data[index+1]
    b: imageData.data[index+2]
    a: imageData.data[index+3]

  setPixel = (imageData,x,y,pixel) ->
    index = (x + y * imageData.width) * 4
    imageData.data[index+0] = pixel.r
    imageData.data[index+1] = pixel.g
    imageData.data[index+2] = pixel.b
    imageData.data[index+3] = pixel.a

  canvas.addEventListener 'dragenter', (evt) ->
    do evt.stopPropagation
    do evt.preventDefault

  canvas.addEventListener 'dragexit', (evt) ->
    do evt.stopPropagation
    do evt.preventDefault

  canvas.addEventListener 'dragover', (evt) ->
    do evt.stopPropagation
    do evt.preventDefault

  canvas.addEventListener 'drop', (evt) ->
    do evt.stopPropagation
    do evt.preventDefault

    files = evt.dataTransfer.files

    if files.length > 0
      file = files[0]
      reader = new FileReader()
      img = document.createElement 'img'
      img.addEventListener 'load', ->
        context.clearRect 0, 0, canvas.width, canvas.height
        context.drawImage img, 0, 0
      reader.onload = (evt) ->
        img.src = evt.target.result
      reader.readAsDataURL file

  histButton = document.querySelector '.hist-button'
  histButton.addEventListener 'click', ->
    histData =
      r:new Uint32Array 256
      g:new Uint32Array 256
      b:new Uint32Array 256
    imageData = context.getImageData 0, 0, canvas.width, canvas.height
    brightest = r: 0,g: 0,b: 0

    for x in [0...imageData.width]
      for y in [0...imageData.height]
        pixel = getPixel imageData,x,y
        histData.r[pixel.r]++
        histData.g[pixel.g]++
        histData.b[pixel.b]++
        brightest.r = histData.r[pixel.r] if histData.r[pixel.r] > brightest.r
        brightest.g = histData.g[pixel.g] if histData.g[pixel.g] > brightest.g
        brightest.b = histData.b[pixel.b] if histData.b[pixel.b] > brightest.b

    scale = 500 / Math.max brightest.r, brightest.g, brightest.b
    histContext.clearRect 0, 0, histCanvas.width, histCanvas.height
    histContext.fillStyle = 'rgba(255, 0, 0, 0.33)'
    for i in [0..255]
      histContext.fillRect i*4, histCanvas.height-histData.r[i]*scale, 4, histData.r[i]*scale
    histContext.fillStyle = 'rgba(0, 255, 0, 0.33)'
    for i in [0..255]
      histContext.fillRect i*4, histCanvas.height-histData.g[i]*scale, 4, histData.g[i]*scale
    histContext.fillStyle = 'rgba(0, 0, 255, 0.33)'
    for i in [0..255]
      histContext.fillRect i*4, histCanvas.height-histData.b[i]*scale, 4, histData.b[i]*scale

  eightArea = (imageData, x, y) ->
    area = new Array 3
    for i in [0..2]
      area[i] = new Array 3
    area[1][1] = getPixel imageData, x, y
    if x isnt 0 and y isnt 0
      area[0][0] = getPixel imageData, x-1, y-1
    if y isnt 0
      area[0][1] = getPixel imageData, x, y-1
    if x isnt imageData.width-1 and y isnt 0
      area[0][2] = getPixel imageData, x+1, y+1
    if x isnt 0
      area[1][0] = getPixel imageData, x-1, y
    if x isnt imageData.width-1
      area[1][2] = getPixel imageData, x+1, y
    if x isnt 0 and y isnt imageData.height-1
      area[2][0] = getPixel imageData, x-1, y+1
    if y isnt imageData.height-1
      area[2][1] = getPixel imageData, x, y+1
    if x isnt imageData.width-1 and y isnt imageData.height-1
      area[2][2] = getPixel imageData, x+1, y+1
    area

  applyFilter = (filter, area) ->
    brightness = r:0, g:0, b:0
    filterSum = 0
    for row in [0...filter.length] when area[row]
      for col in [0...filter[row].length] when area[row][col]
        brightness.r += area[row][col].r*filter[row][col]
        brightness.g += area[row][col].g*filter[row][col]
        brightness.b += area[row][col].b*filter[row][col]
        filterSum += filter[row][col]
    r:brightness.r/filterSum
    g:brightness.g/filterSum
    b:brightness.b/filterSum
    a: 255

  lowpassFilter = (context, matrix) ->
    imageData = context.getImageData 0, 0, canvas.width, canvas.height
    filteredImageData = context.createImageData canvas.width, canvas.height
    for x in [0..imageData.width]
      for y in [0..imageData.height]
        area = eightArea imageData, x, y
        pixel = applyFilter matrix, area
        setPixel filteredImageData, x, y, pixel
    context.putImageData filteredImageData, 0, 0

  lpfOneButton = document.querySelector '.lpf1-button'
  lpfOneButton.addEventListener 'click', ->
    lowpassFilter context, [
      [1, 1, 1]
      [1, 1, 1]
      [1, 1, 1]
    ]

  lpfTwoButton = document.querySelector '.lpf2-button'
  lpfTwoButton.addEventListener 'click', ->
    lowpassFilter context, [
      [1, 1, 1]
      [1, 2, 1]
      [1, 1, 1]
    ]

  lpfThreeButton = document.querySelector '.lpf3-button'
  lpfThreeButton.addEventListener 'click', ->
    lowpassFilter context, [
      [1, 2, 1]
      [2, 4, 2]
      [1, 2, 1]
    ]

  linearContrastButton = document.querySelector '.lcontrast-button'
  gminInput = document.querySelector '.g-min-input'
  gmaxInput = document.querySelector '.g-max-input'

  linearContrastButton.addEventListener 'click', ->
    gmin = gminInput.value
    gmax = gmaxInput.value

    imageData = context.getImageData 0, 0, canvas.width, canvas.height
    filteredImageData = context.createImageData canvas.width, canvas.height
    brightest = r:0, g:0, b:0
    darkest = r:0, g:0, b:0
    for x in [0..imageData.width]
      for y in [0..imageData.height]
        pixel = getPixel imageData, x, y
        if pixel.r > brightest.r
          brightest.r = pixel.r
        if pixel.g > brightest.g
          brightest.g = pixel.g
        if pixel.b > brightest.b
          brightest.b = pixel.b
        if pixel.r < darkest.r
          darkest.r = pixel.r
        if pixel.g < darkest.g
          darkest.g = pixel.g
        if pixel.b < darkest.b
          darkest.b = pixel.b

    for x in [0..imageData.width]
      for y in [0..imageData.height]
        pixel = getPixel imageData, x, y
        pixel.r = (pixel.r - darkest.r) / (brightest.r - darkest.r) * (gmax-gmin) + gmin
        pixel.g = (pixel.g - darkest.g) / (brightest.g - darkest.r) * (gmax-gmin) + gmin
        pixel.b = (pixel.b - darkest.b) / (brightest.b - darkest.r) * (gmax-gmin) + gmin
        setPixel filteredImageData, x, y, pixel

    context.putImageData filteredImageData, 0, 0
