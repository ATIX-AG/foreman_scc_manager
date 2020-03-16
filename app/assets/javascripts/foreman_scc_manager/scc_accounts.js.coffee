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
  $("body").on "change", "span.scc_product_checkbox input", (event) ->
    target = event.target
    if target.checked
      scc_products_after_checked target
    else
      scc_products_after_unchecked target
  $("body").on "click", "a.edit_deferrer", (event) ->
    event.preventDefault()
    $("a.edit_deferree", $(event.target).closest("tr"))[0].click()
  $("body").on "click", "#test_scc_connection_btn", (event) ->
    $('.tab-error').removeClass('tab-error')
    $('#connection_test_result')[0].innerHTML = ''
    $('#test_scc_connection_indicator').show()
    $.ajax event.target.parentNode.dataset['url'],
      type: 'POST'
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
        $('#scc_account_login').closest('.form-group').addClass('tab-error')
        $('#scc_account_password').closest('.form-group').addClass('tab-error')
        $('#scc_account_base_url').closest('.form-group').addClass('tab-error')
        $('#connection_test_result')[0].innerHTML = 'Connection test failed!'
        $('#scc_account_login').focus()
      complete: (result) ->
        $('#test_scc_connection_indicator').hide()
