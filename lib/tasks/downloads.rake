namespace :downloads do

  desc 'Clean up old downloads'
  task cleanup: :environment do
    Download.cleanup(60 * 60 * 24) # max 1 day old
  end

  desc 'Expire all downloads'
  task expire: :environment do
    Download.where(expired: false).each(&:expire)
  end

end
