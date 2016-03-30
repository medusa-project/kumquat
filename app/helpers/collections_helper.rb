module CollectionsHelper

  def collections_as_list(collections)
    html = '<ol>'
    collections.each do |col|
      html += '<li>'
      html += '<div>'
      html += '<span class="pt-title">'
      html += link_to(col.title, col.access_url, target: '_blank')
      html += '</span>'
      html += '<br>'
      html += '<span class="pt-description">'
      html += truncate(col.description, length: 400)
      html += '</span>'
      html += '</div>'
      html += '</li>'
    end
    html += '</ol>'
    raw(html)
  end

end