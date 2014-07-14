require "fog"
require "active_support/core_ext/string"

module Middleman
  module Cli

    class CloudFrontCDN
      INVALIDATION_LIMIT = 1000

      def self.key
        "cloudfront"
      end

      def self.example_configuration
        <<-TEXT
  cdn.cloudfront = {
    access_key_id: 'I',          # default ENV['AWS_ACCESS_KEY_ID']
    secret_access_key: 'love',   # default ENV['AWS_SECRET_ACCESS_KEY']
    distribution_id: 'cats'
  }
TEXT
      end

      def invalidate(options, files)
        puts "## Invalidating files on CloudFront"

        options[:access_key_id] ||= ENV['AWS_ACCESS_KEY_ID']
        options[:secret_access_key] ||= ENV['AWS_SECRET_ACCESS_KEY']
        [:access_key_id, :secret_access_key, :distribution_id].each do |key|
          raise StandardError, "Configuration key cloudfront[:#{key}] is missing." if options[key].blank?
        end

        cloudfront = Fog::CDN.new({
          :provider               => 'AWS',
          :aws_access_key_id      => options[:access_key_id],
          :aws_secret_access_key  => options[:secret_access_key]
        })

        distribution = cloudfront.distributions.get(options[:distribution_id])

        if files.count <= INVALIDATION_LIMIT
          puts "Invalidating #{files.count} files. It might take 10 to 15 minutes until all files are invalidated."
          puts 'Please check the AWS Management Console to see the status of the invalidation.'
          invalidation = distribution.invalidations.create(:paths => files)
          raise StandardError, %(Invalidation status is #{invalidation.status}. Expected "InProgress") unless invalidation.status == 'InProgress'
        else
          slices = files.each_slice(INVALIDATION_LIMIT)
          puts "Invalidating #{files.count} files in #{slices.count} batch(es). It might take 10 to 15 minutes per batch until all files are invalidated."
          slices.each_with_index do |slice, i|
            puts "Invalidating batch #{i + 1}..."
            invalidation = distribution.invalidations.create(:paths => slice)
            invalidation.wait_for { ready? } unless i == slices.count - 1
          end
        end
      end
    end

  end
end
