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

    class_name = args.shift.capitalize if args[0].is_a?(String)
    new_class = Class.new do
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
        if attribute.nil?
          attribute
        elsif attribute.respond_to?(:dig)
          attribute.dig(*names)
        end
      end
    
      def size
        instance_variables.size
      end
    
      def length
        instance_variables.length
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
        result = to_a
        args.map{ |arg| result[arg]}
      end
    
      def ==(other)
        if other.is_a? self.class
          instance_variables.each do |variable|
            return false if instance_variable_get(variable) != other.instance_variable_get(variable)
          end
          true
        else
          false
        end
      end

      class_eval(&block) if block_given?

    end

      const_set(class_name, new_class) if class_name
      new_class
      
  end
end
