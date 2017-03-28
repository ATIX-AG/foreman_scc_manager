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
