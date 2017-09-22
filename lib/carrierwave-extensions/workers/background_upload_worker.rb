module CarrierwaveExtensions
  module Workers
    class BackgroundUploadWorker
      include Sidekiq::Worker

      # Process remote uploads - initialized via background_mounted_as_url
      def perform(type, type_id, mounted_as, remote_url)
        type = type.constantize

        if type.respond_to? :with_deleted
          object = type.with_deleted.find(type_id)
        else
          object = type.find(type_id)
        end

        Sidekiq.logger.info "uploader: #{object.send(mounted_as).class}"

        object.update(:"remote_#{mounted_as}_url" => remote_url)
        
        if object.respond_to? :"#{mounted_as}_processing"
          object.update_attribute(:"#{mounted_as}_processing", false)
        end

      end
    end
  end
end
