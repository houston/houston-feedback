$.fn.extend
  
  between: (element0, element1)->
    $context = $(this)
    index0 = $context.index(element0)
    index1 = $context.index(element1)
    if index0 <= index1 then @slice(index0, index1 + 1) else @slice(index1, index0 + 1)
