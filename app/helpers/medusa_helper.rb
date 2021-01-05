module MedusaHelper

  def medusa_directory_link(uuid, dir)
    link_to(dir.name, dir.url)
  rescue Medusa::NotFoundError
    raw("<code>#{uuid}</code> (does not exist)")
  end

end