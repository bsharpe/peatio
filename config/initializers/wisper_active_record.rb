if defined?(Wisper)
  module Wisper
    module ActiveRecord
      # ActiveRecord extension to automatically publish events for CRUD lifecycle
      # see https://github.com/krisleech/wisper/wiki/Rails-CRUD-with-ActiveRecord
      # see https://github.com/krisleech/wisper-activerecord
      module Publisher
        extend ActiveSupport::Concern
        include Wisper::Publisher

        included do
          after_commit :broadcast_create, on: :create
          after_commit :broadcast_update, on: :update
          after_commit :broadcast_destroy, on: :destroy
        end

        private

        # broadcast MODEL_created event to subscribed listeners
        def broadcast_create
          broadcast(:after_create, self)
        end

        # broadcast MODEL_updated event to subscribed listeners
        # pass the set of changes for background jobs to know what changed
        # see https://github.com/krisleech/wisper-activerecord/issues/17
        def broadcast_update
          user = Thread.current[:user]
          broadcast(:after_update, self, previous_changes.with_indifferent_access, user) if previous_changes.any?
        end

        # broadcast MODEL_destroyed to subscribed listeners
        # pass a serialized version of the object attributes
        # for listeners since the object is no longer accessible in the database
        def broadcast_destroy
          broadcast(:after_destroy, attributes.with_indifferent_access)
        end

      end
    end
  end
end