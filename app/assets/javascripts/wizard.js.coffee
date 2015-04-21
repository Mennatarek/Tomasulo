
#  Activate the tooltips      

#check number of tabs and fill the entire row

# Disable the posibility to click on tabs

# If it's the last tab then hide the last button and show the finish instead

# Prepare the preview for profile picture

#functions for demo purpose

#Function to show image before upload

searchVisible = 0
transparent = true
$(document).ready ->
  $("[rel=\"tooltip\"]").tooltip()
  $("#wizard").bootstrapWizard
    tabClass: "nav nav-pills"
    nextSelector: ".btn-next"
    previousSelector: ".btn-previous"
    onInit: (tab, navigation, index) ->
      $total = navigation.find("li").length
      $width = 100 / $total
      $display_width = $(document).width()
      $width = 50  if $display_width < 400 and $total > 3
      navigation.find("li").css "width", $width + "%"
      return

    onTabClick: (tab, navigation, index) ->
      false

    onTabShow: (tab, navigation, index) ->
      $total = navigation.find("li").length
      $current = index + 1
      wizard = navigation.closest(".wizard-card")
      if $current == 1
          $(wizard).find(".btn-compile").show()
          $(wizard).find(".btn-next").hide()
          $(wizard).find(".btn-finish").hide()
          $("#L1 *").attr("disabled", false)
          $("#L2 *").attr("disabled", false)
          $("#L3 *").attr("disabled", false)      
      else
        $(wizard).find(".btn-compile").hide()
        if $current >= $total
          $(wizard).find(".btn-next").hide()
          $(wizard).find(".btn-finish").show()
        else
          $(wizard).find(".btn-next").show()
          $(wizard).find(".btn-finish").hide()
      return

  $("[data-toggle=\"wizard-radio\"]").click (event) ->
    wizard = $(this).closest(".wizard-card")
    wizard.find("[data-toggle=\"wizard-radio\"]").removeClass "active"
    $(this).addClass "active"
    $(wizard).find("[type=\"radio\"]").removeAttr "checked"
    $(this).find("[type=\"radio\"]").attr "checked", "true"
    return

  $height = $(document).height()
  $(".set-full-height").css "height", $height
  return

  $(".step").on "click", ->
    alert("sdkjhsjdhsj")
    steps = $(this).siblings()[0]
    return  if steps.value is 1 and $(this).hasClass("down") or + steps.data("max") is + steps.value and $(this).hasClass("up")
    if $(this).hasClass("up")
      $(".steps").text steps.value * 2
    else
      $(".steps").text steps.value / 2
    return
  # editor.gotoLine(4);
# window.removeDefaultText = ->
#   if editor.getValue() == "Enter Your code here"
#     editor.setValue("")
#   return
window.submit_form = ->
  levels = $("#cache_levels_selection")[0].value
  if levels < 3
    $("#L3 *").remove()
  if levels < 2
    $("#L2 *").remove()
  $("#new_program").submit()

window.compileProgram = ->
  $.ajax
    type: "POST"
    url: 'programs/compile'
    data: {"code": editor.getValue()}
    success: (data, textStatus, jqXHR) -> 
      if data.compiled == true
        alert("compiled")
        levels = $("#cache_levels_selection")[0].value
        $("#program_code")[0].value = editor.getValue()
        $('#wizard').bootstrapWizard('next')
        if levels < 3
          $("#L3 *").attr("disabled", true)
        if levels < 2
          $("#L2 *").attr("disabled", true)
      else
        alert("Syntax Error at line " + (data.compiled + 1))

window.isNumber = (event) ->
  if event
    charCode = (if (event.which) then event.which else event.keyCode)
    return false  if charCode isnt 190 and charCode > 31 and (charCode < 48 or charCode > 57) and (charCode < 96 or charCode > 105) and (charCode < 37 or charCode > 40) and charCode isnt 110 and charCode isnt 8 and charCode isnt 46
  true
