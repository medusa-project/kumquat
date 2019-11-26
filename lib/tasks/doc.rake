namespace :doc do

  desc 'Generate documentation'
  task :generate => :environment do |task, args|
    doc_path = File.join(Rails.root, 'doc')
    FileUtils.rm_rf(doc_path)
    `yard --markup markdown`
    if RUBY_PLATFORM.include?('darwin')
      `open doc/index.html`
    else
      puts "Documentation generated at #{doc_path}"
    end
  end

end
