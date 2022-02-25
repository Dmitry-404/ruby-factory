# frozen_string_literal: true

# * Here you must define your `Factory` class.
# * Each instance of Factory could be stored into variable. The name of this variable is the name of created Class
# * Arguments of creatable Factory instance are fields/attributes of created class
# * The ability to add some methods to this class must be provided while creating a Factory
# * We must have an ability to get/set the value of attribute like [0], ['attribute_name'], [:attribute_name]
#
# * Instance of creatable Factory class should correctly respond to main methods of Struct
# - each
# - each_pair
# - dig
# - size/length
# - members
# - select
# - to_a
# - values_at
# - ==, eql?

class Factory
  def self.new(*args, &block)
    return const_set(class_name_from_arguments(args), new_class(args, &block)) if class_name_is_first_arg?(args)

    new_class(args, &block)
  end

  class << self
    private

    def new_class(args, &block) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
      Class.new do
        args.each { |x| attr_accessor x }

        define_method :initialize do |*attribute|
          raise ArgumentError if attribute.length > args.length

          args.each.with_index do |arg, i|
            instance_variable_set("@#{arg}", attribute[i])
          end
        end

        def [](variable)
          instance_variable_get(variable.is_a?(Integer) ? instance_variables[variable] : "@#{variable}")
        end

        def []=(index, variable)
          instance_variable_set(index.is_a?(Integer) ? instance_variables[index] : "@#{index}", variable)
        end

        def each
          instance_variables.map { |attribute| yield(instance_variable_get(attribute)) }
        end

        def each_pair
          instance_variables.map { |attribute| yield(attribute.to_s.delete('@'), instance_variable_get(attribute)) }
        end

        def dig(name, *names)
          attribute = self[name]
          return attribute if attribute.nil?

          attribute.dig(*names) if attribute.respond_to?(:dig)
        end

        def size
          instance_variables.size
        end

        def members
          instance_variables.map { |attribute| attribute.to_s.delete('@').to_sym }
        end

        def select
          instance_variables.map do |attribute|
            instance_variable_get(attribute) if yield(instance_variable_get(attribute))
          end.compact
        end

        def to_a
          instance_variables.map { |attribute| instance_variable_get(attribute) }
        end

        def values_at(*args)
          args.map { |arg| to_a[arg] }
        end

        def ==(other)
          return false unless other.is_a? self.class

          instance_variables.each do |variable|
            return false if instance_variable_get(variable) != other.instance_variable_get(variable)
          end
          true
        end

        alias_method :length, :size
        alias_method :eql?, :==
        class_eval(&block) if block_given?
      end
    end

    def class_name_from_arguments(args)
      args.shift.capitalize
    end

    def class_name_is_first_arg?(args)
      args[0].is_a?(String)
    end
  end
end
