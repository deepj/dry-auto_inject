# frozen_string_literal: true

require 'dry/auto_inject/strategies/constructor'
require 'dry/auto_inject/method_parameters'

module Dry
  module AutoInject
    class Strategies
      # @api private
      class Kwargs < Constructor
        private

        def define_new
          class_mod.class_exec(container, dependency_map) do |container, dependency_map|
            map = dependency_map.to_h

            define_method :new do |*args, **kwargs|
              map.each do |name, identifier|
                kwargs[name] ||= container[identifier]
              end

              super(*args, **kwargs)
            end
          end
        end

        def define_initialize(klass)
          super_parameters = Dry::AutoInject.super_parameters(klass, :initialize).first

          if super_parameters.splat? || super_parameters.sequential_arguments?
            define_initialize_with_splat(super_parameters)
          else
            define_initialize_with_keywords(super_parameters)
          end

          self
        end

        def define_initialize_with_keywords(super_parameters)
          assign_dependencies = method(:assign_dependencies)
          slice_kwargs = method(:slice_kwargs)

          instance_mod.class_exec(dependency_map) do |dependency_map|
            define_method :initialize do |**kwargs|
              assign_dependencies.(kwargs, self)

              super_kwargs = slice_kwargs.(kwargs, super_parameters)

              if super_kwargs.any?
                super(super_kwargs)
              else
                super()
              end
            end
          end
        end

        def define_initialize_with_splat(super_parameters)
          assign_dependencies = method(:assign_dependencies)
          slice_kwargs = method(:slice_kwargs)

          instance_mod.class_exec(dependency_map) do |dependency_map|
            define_method :initialize do |*args, **kwargs|
              assign_dependencies.(kwargs, self)

              if super_parameters.splat?
                super(*args, kwargs)
              else
                super_kwargs = slice_kwargs.(kwargs, super_parameters)

                if super_kwargs.any?
                  super(*args, super_kwargs)
                else
                  super(*args)
                end
              end
            end
          end
        end

        def assign_dependencies(kwargs, destination)
          dependency_map.names.each do |name|
            # Assign instance variables, but only if the ivar is not
            # previously defined (this improves compatibility with objects
            # initialized in unconventional ways)
            unless kwargs[name].nil? && destination.instance_variable_defined?(:"@#{name}")
              destination.instance_variable_set :"@#{name}", kwargs[name]
            end
          end
        end

        def slice_kwargs(kwargs, super_parameters)
          kwargs.select do |key|
            !dependency_map.names.include?(key) || super_parameters.keyword?(key)
          end
        end
      end

      register_default :kwargs, Kwargs
    end
  end
end
