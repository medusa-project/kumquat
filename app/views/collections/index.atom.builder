atom_feed do |feed|
  feed.title('Collections')

  feed.updated(@updated)

  @collections.each do |col|
    feed.entry(col) do |entry|
      entry.title(col.title)
      entry.content(col.description, type: 'text')

      entry.author do |author|
        author.name(Option::string(Option::Keys::ORGANIZATION_NAME))
      end
    end
  end
end
