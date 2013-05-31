# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

loading_panel_id = 'loadingPanel'
opts = {
lines: 11,
length: 21,
width: 13,
radius: 24,
corners: 1,
rotate: 1,
color: '#000',
speed: 0.8,
trail: 76,
shadow: true,
hwaccel: false,
className: 'spinner',
zIndex: 2e9,
top: 'auto',
left: 'auto'
}

###
target = document.getElementById loading_panel_id
spinner = new Spinner(opts).spin target
###

$( document).ready ->
  $bar = $ '.sim-loading-bar'
  b_width = $(".container-fluid > .progress").width()
  step = b_width * 0.3
  $('.agency-listing').hide()

  watch_loading_progress = () ->
    if $bar.width() >= b_width
      clearInterval process_watched
      $('.progress') .removeClass 'active'
      $( "#" + loading_panel_id).fadeOut()
      $('.agency-listing').fadeToggle(1000)
      $('.sim-loading-bar').closest('.container-fluid').fadeToggle(500)
    else
      $bar.width $bar.width() + step

    $bar.text Math.min(Math.ceil($bar.width() * 100 / b_width), 100) + "%"


  target = document.getElementById loading_panel_id
#spinner = new Spinner(opts).spin target*/
  process_watched = setInterval watch_loading_progress, 100