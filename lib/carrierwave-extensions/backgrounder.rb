# Uploadable hooks into the CarrierWave mount_uploader class method
# and uses the mounted column to create a new attribute on the model
# eg. model.background_mounted_column_url
# after_commit processes any url on this attribute in a sidekiq job

module CarrierwaveExtensions
  module Backgrounder
    extend ActiveSupport::Concern

    def upload(mounted_as, remote_url)
      CarrierwaveExtensions::Workers::BackgroundUploadWorker.perform_async(self.class.name, self.id, mounted_as, remote_url)
    end

    module ClassMethods
      def mount_uploader(column, uploader=nil, options={}, &block)
        super
        class_eval <<-RUBY
          attr_accessor :background_#{column}_url

          before_save  :set_#{column}_processing
          after_commit :process_#{column}_url

          def process_#{column}_url
            return if background_#{column}_url.blank?
            self.upload('#{column}', background_#{column}_url)
            self.background_#{column}_url = nil
          end

          def set_#{column}_processing
            return if background_#{column}_url.blank?
            self.#{column}_processing = true if respond_to?(:#{column}_processing)
          end
        RUBY
      end
    end
  end
end

ActiveRecord::Base.send :include, CarrierwaveExtensions::Backgrounder