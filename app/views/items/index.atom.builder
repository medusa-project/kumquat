atom_feed do |feed|
  if @collection
    feed.title(@collection.title)
  else
    feed.title('Items')
  end

  feed.updated(@updated)

  @items.each do |item|
    feed.entry(item) do |entry|
      entry.title(item.title)
      entry.content(item.description, type: 'text')

      entry.author do |author|
        author.name(Setting::string(Setting::Keys::ORGANIZATION_NAME))
      end
    end
  end
end
