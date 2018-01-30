if defined?(Wisper)

  def process_models(dir = nil, bases = [])
    dir ||= Rails.root.join('app', 'models')
    Dir.foreach(dir) do |filename|
      next if %w[. .. concerns .gitkeep].include?(filename)
      dir_name = File.join(dir, filename)
      if File.directory?(dir_name)
        bases.push filename.camelize
        process_models(dir_name, bases)
      else
        klass_name = ""
        klass_name << "#{bases.join('::')}::" if bases.any?
        klass_name << File.basename(filename, '.rb').camelize.to_s
        klass = klass_name.constantize
        next unless klass.ancestors.include?(ApplicationRecord)
        begin
          notifier_klass_name = "#{klass_name}Subscriber"
          notifier_klass = notifier_klass_name.constantize
          Wisper.subscribe(notifier_klass.new, scope: klass, async: Rails.env.production?)
          puts "> #{notifier_klass} enabled".cyan
        rescue NameError => e
          # puts "#{notifier_klass_name} NOT FOUND".light_black
        end
      end
    end
    bases.pop
  end

  process_models

  # Link any Controllers to their <Controller>Subscriber class
  Dir[Rails.root.join('app/controllers/api/*.rb').to_s].each do |filename|
    base_name = File.basename(filename, '.rb').camelize
    klass = "API::#{base_name}".constantize
    next unless klass.singleton_class.included_modules.map(&:to_s).include?("Wisper::Publisher::ClassMethods")
    begin
      notifier_klass = "#{base_name}Subscriber".constantize
      klass.subscribe(notifier_klass.new, async: Rails.env.production?)
      # puts "> #{notifier_klass} is subscribing to #{klass}".cyan
    rescue NameError
      # ignore
    end
  end
end
