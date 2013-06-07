
default_size = 250

last_image = null

read_files = (f, container) ->
  form_data = null
  if !!window.FormData
    form_data = new FormData()
  for i, _file of f
    if form_data
      form_data.append 'file', _file
      preview_file _file, container
      _file

preview_file = (f, container) ->
  file_reader = typeof FileReader not 'undefined'
  if file_reader
    reader = new FileReader()
    reader.onload = (evt) ->
      img = new Image()
      img.src = evt.target.result
      img.width = default_size
      #$(container).append img
      last_image = img
      $(container).trigger 'fileadded'
    reader.readAsDataURL f
  else
    size = if file.size then file.size / 1024|0 else "unknown"
    container.append $ "<p/>", { html : "Uploaded #{file.name} - size : #{size}"}

$(document).ready ->
  container = $("#pictureDropBox").resizable helper: "ui-resizable-helper"
  nb_img = 0
  container.on {
  'dragenter' : (e) ->
    $(this).addClass 'hover'
  'dragleave' : (e) ->
    console.log e
    $(this).removeClass 'hover'
  'dragend': (e) ->
    e.preventDefault()
    return false
    $(this).removeClass 'hover'
  'drop': (e) ->
    e.preventDefault()
    that = this
    if e.originalEvent.dataTransfer.files.length
      $(that).removeClass 'hover'
      read_files e.originalEvent.dataTransfer.files, that
    else
      console.log 'no data detected'
    return false
  'fileadded' : (e) ->
    image_preview_placeholder = document.getElementById "imagePreview"
    $(this).removeClass 'hover'
    if last_image isnt null
      image_preview_placeholder.src = last_image.src
      image_preview_placeholder.style.width = '100px'
      #image_preview_placeholder.style.height = '100px'
  }

  $(document.body).bind 'drop dragover', (e) ->
    e.preventDefault()
    return false

  $("#sortable1, #sortable2").sortable({
    placeholder: "ui-state-highlight",
    update : (e, ui) ->
      console.log 'test'
    stop : (e, ui) ->
      $t = $ 'div[class^="span"]', $ this
      $t.each  (i, elt) ->
        console.log 'test'
        console.log "Item at #{i} is #{$(elt).html()}"
  })
  $( "#sortable" ).disableSelection() #.sortable({revert:true})