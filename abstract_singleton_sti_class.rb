#this module allows you to make parent classes of STI
#abstract only, and must be derived off of.
#requires the 'acts_as_singleton' gem
#also, checks that there is a corresponding row in the database(if not abstract)
#a class becomes "abstract" automatically if it is subclassed
#
#for the database check to work, there must be at least one validation on the model
#so the first || create call in acts_as_singleton will fail and return an unsaved object
module AbstractSingletonStiClass

  module InstanceMethods
  end
  
  module ClassMethods
    
    def abstract?
      @@abstract_classes.include?(self)
    end
    
    def instance_with_abstract_check
      if @@abstract_classes.include?(self)
        raise "must be called only on subclasses" 
      end
      
      return instance_without_abstract_check.tap{|o| raise "must have a row in the database before using this class" if o.new_record? }
    end
    
    #here is the magic that automagically makes classes "abstract"
    #when they are inherited
    def inherited(child)
      @@abstract_classes ||= []
      @@abstract_classes << self unless @@abstract_classes.include?(self)
    end
    
    def self.extended(base)
      base.class_eval do
        acts_as_singleton
        class << self
          alias_method_chain :instance, :abstract_check
        end
      end
    end 
  end
  
  module ActiveRecordMethods
    def acts_as_abstract_singleton_sti
      include AbstractSingletonStiClass
    end
  end
  
  def self.included(base)
    base.send :include, InstanceMethods
    base.send :extend, ClassMethods
  end
end

#inject class method into AR::Base
class ActiveRecord::Base
  extend AbstractSingletonStiClass::ActiveRecordMethods
end
