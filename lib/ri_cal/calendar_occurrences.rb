module RiCal
  module CalendarOccurrences
    # Return occurrences for all recurrable subcomponents of a calendar
    def occurrences(options={})
      occs = recurring_subcomponents.inject([]) do |memo, collection|
        _, components = collection

        recurrable(components).each do |component|
          component_instances = instances(component.uid, components)

          add_occurrences_in_range_excluding_instances(memo, component, component_instances, options)
          add_instances_in_range(memo, component_instances, options)
        end
      
        memo
      end.sort{|a,b| a.dtstart <=> b.dtstart}

      options[:count] ? occs.first([options[:count],0].max) : occs
    end
    
    private

    def add_occurrences_in_range_excluding_instances(memo, component, instances, options)
      unless component.bounded?(options)
        raise ArgumentError.new("This component is unbounded, cannot enumerate occurrences!")
      end

      yielded = 0
      component.each(options.reject{|k,_|:count == k}) do |occurrence|
        break if yielded >= options[:count] if options[:count]
        
        unless cancelled?(instances, occurrence)
          memo << occurrence
          yielded += 1
        end
      end
    end
    
    def add_instances_in_range(memo, instances, options)
      instances.each do |override|
        if instance = override.occurrences(options).first
          memo << instance
        end
      end
    end      
    
    def cancelled?(instances, occurrence)
      instances.find{ |i| i.recurrence_id == occurrence.dtstart }
    end

    def recurring_subcomponents
      subcomponents.select{ |k,v| %(VEVENT VTODO VJOURNAL).include?(k) } 
    end
    
    def recurrable(components)
      components.select{|c| ! c.recurrence_id}
    end

    def instances(uid, components)
      components.select{|c| uid == c.uid && c.recurrence_id}
    end
  end
end
