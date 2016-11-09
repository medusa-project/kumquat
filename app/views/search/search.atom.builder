atom_feed do |feed|
  feed.title('Search')

  feed.updated(@updated)

  @entities.each do |entity|
    feed.entry(entity) do |entry|
      entry.title(entity.title)
      entry.content(entity.description, type: 'text')

      entry.author do |author|
        author.name(Option::string(Option::Key::ORGANIZATION_NAME))
      end
    end
  end
end
