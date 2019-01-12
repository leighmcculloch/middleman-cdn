require "fog/aws"
require "active_support/core_ext/string"

module Middleman
  module Cli

    class CloudFrontCDN < BaseCDN
      INVALIDATION_LIMIT = 1000

      def self.key
        "cloudfront"
      end

      def self.example_configuration_elements
        {
          access_key_id: ['"..."', "# default ENV['AWS_ACCESS_KEY_ID']"],
          secret_access_key: ['"..."', "# default ENV['AWS_SECRET_ACCESS_KEY']"],
          distribution_id: ['"..."', ""]
        }
      end

      def invalidate(options, files, all: false)
        options[:access_key_id] ||= ENV['AWS_ACCESS_KEY_ID']
        options[:secret_access_key] ||= ENV['AWS_SECRET_ACCESS_KEY']
        [:access_key_id, :secret_access_key, :distribution_id].each do |key|
          if options[key].blank?
            say_status(ANSI.red{ "Error: Configuration key cloudfront[:#{key}] is missing." })
            raise
          end
        end

        cloudfront = ::Fog::CDN.new({
          :provider               => 'AWS',
          :aws_access_key_id      => options[:access_key_id],
          :aws_secret_access_key  => options[:secret_access_key]
        })

        distribution = cloudfront.distributions.get(options[:distribution_id])

        if files.count <= INVALIDATION_LIMIT
          say_status("Invalidating #{files.count} files... ", newline: false)
          invalidation = distribution.invalidations.create(:paths => files)
          if invalidation.status != 'InProgress'
            say_status(ANSI.red{ ANSI.bold + "Invalidation status is #{invalidation.status}. Expected 'InProgress'." }, header: false)
            raise
          end
          say_status(ANSI.green{ "✔" }, header: false)
        else
          slices = files.each_slice(INVALIDATION_LIMIT)
          say_status("Invalidating #{files.count} files in #{slices.count} batch(es) ")
          slices.each_with_index do |slice, i|
            say_status("Invalidating batch #{i + 1}... ", newline: false)
            invalidation = distribution.invalidations.create(:paths => slice)
            invalidation.wait_for { ready? } unless i == slices.count - 1
            say_status(ANSI.green{ "✔" }, header: false)
          end
        end
        say_status("It might take 10 to 15 minutes until all files are invalidated.")
        say_status('Please check the AWS Management Console to see the status of the invalidation.')
      end
    end

  end
end
