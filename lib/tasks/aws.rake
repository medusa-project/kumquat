namespace :dls do

  desc 'Check access to AWS resources'
  task :aws_check => :environment do |task, args|
    print "Checking access to RDS... "
    Binary.all.limit(1).first
    print "OK\n"

    print "Checking read access to #{MedusaS3Client::BUCKET} bucket... "
    MedusaS3Client.instance.head_object(
      bucket: MedusaS3Client::BUCKET,
      key: "162/2204/6713580/access/6713580_02.jp2")
    print "OK\n"

    print "Checking access to OpenSearch... "
    OpensearchClient.instance.indexes
    print "OK\n"

    print "Checking access to Lambda... "
    Binary.where(media_type: "image/jpeg").first.detect_text
    print "OK\n"
  end

end
