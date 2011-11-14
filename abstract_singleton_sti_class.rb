# module AbstractSingletonStiClass
# 
# Copyright 2011 - Peter Philips
# 
# This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#  See readme for usage: https://github.com/synth/AbstractSingletonStiClass
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
      
      return instance_without_abstract_check.tap{|o| 
        raise "must have a row in the database before using #{o.class}" if o.new_record? and ( File.basename($0) == "rake" && ARGV.include?("db:migrate") )
      }
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
