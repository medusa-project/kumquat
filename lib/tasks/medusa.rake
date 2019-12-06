namespace :medusa do

  namespace :repositories do

    desc 'Sync Medusa repositories'
    task :sync => :environment do
      MedusaRepository.sync_all
    end

  end

end