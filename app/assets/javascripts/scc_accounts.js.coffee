scc_products_after_checked = (target) ->
  if target.parentNode.dataset.parent
    parent = $("#" + target.parentNode.dataset.parent + " input")[0]
    if !parent.checked && !parent.disabled
      parent.checked = true
      scc_products_after_checked(parent)

scc_products_after_unchecked = (target) ->
  $("span.scc_product_checkbox input", target.parentNode.parentNode).each (index, child) ->
    if child.checked && !child.disabled
      child.checked = false
      scc_products_after_unchecked(child)

$ ->
  $("div#content").on "change", "span.scc_product_checkbox input", (event) ->
    target = event.target
    if target.checked
      scc_products_after_checked target
    else
      scc_products_after_unchecked target
  $("div#content").on "click", "a.edit_deferrer", (event) ->
    event.preventDefault()
    $("a.edit_deferree", $(event.target).parents("tr")[0])[0].click()
  $("body").on "click", "#test_scc_connection_btn", (event) ->
    console.log event.target.parentNode.dataset['url']
    $('.tab-error').removeClass('tab-error')
    $('#test_scc_connection_indicator').show()
    $.ajax event.target.parentNode.dataset['url'],
      type: 'PUT'
      dataType: 'JSON'
      data: $('form').serialize()
      success: (result) ->
        $('#test_scc_connection_btn').addClass('btn-success')
        $('#test_scc_connection_btn').removeClass('btn-default')
        $('#test_scc_connection_btn').removeClass('btn-danger')
      error: (result) ->
        $('#test_scc_connection_btn').addClass('btn-danger')
        $('#test_scc_connection_btn').removeClass('btn-default')
        $('#test_scc_connection_btn').removeClass('btn-success')
      complete: (result) ->
        $('#test_scc_connection_indicator').hide()
