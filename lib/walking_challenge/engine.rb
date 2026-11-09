# frozen_string_literal: true

module WalkingChallenge
  class Engine < ::Rails::Engine
    engine_name WalkingChallenge::PLUGIN_NAME
    isolate_namespace WalkingChallenge
    config.autoload_paths << File.join(config.root, "lib")
  end
end
