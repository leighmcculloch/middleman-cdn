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
          ::Middleman::Cli::CDN.say_status("cloudfront".yellow + " invalidating #{files.count} files... ", incomplete: true)
          invalidation = distribution.invalidations.create(:paths => files)
          raise StandardError, %(Invalidation status is #{invalidation.status}. Expected "InProgress") unless invalidation.status == 'InProgress'
          ::Middleman::Cli::CDN.say_status("✓".light_green, header: false)
        else
          slices = files.each_slice(INVALIDATION_LIMIT)
          ::Middleman::Cli::CDN.say_status("cloudfront".yellow + " invalidating #{files.count} files in #{slices.count} batch(es) ")
          slices.each_with_index do |slice, i|
            ::Middleman::Cli::CDN.say_status("cloudfront".yellow + " invalidating batch #{i + 1}... ", incomplete: true)
            invalidation = distribution.invalidations.create(:paths => slice)
            invalidation.wait_for { ready? } unless i == slices.count - 1
            ::Middleman::Cli::CDN.say_status("✓".light_green, header: false)
          end
        end
        ::Middleman::Cli::CDN.say_status("cloudfront".yellow + " It might take 10 to 15 minutes until all files are invalidated.")
        ::Middleman::Cli::CDN.say_status("cloudfront".yellow + ' Please check the AWS Management Console to see the status of the invalidation.')
      end
    end

  end
end
