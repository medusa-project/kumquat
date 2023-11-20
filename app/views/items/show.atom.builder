atom_feed do |feed|
  feed.title(@item.title)

  feed.updated(@item.updated_at)


  feed.entry(@item) do |entry|
    entry.title(@item.title)
    entry.content(@item.description, type: 'text')

    entry.author do |author|
      author.name(Setting::string(Setting::Keys::ORGANIZATION_NAME))
    end
  end

end
