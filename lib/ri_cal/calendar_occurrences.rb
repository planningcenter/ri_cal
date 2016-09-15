module RiCal
  module CalendarOccurrences
    # Return occurrences for all recurrable subcomponents of a calendar
    def occurrences(options={})
      occs = recurring_subcomponents.inject([]) do |memo, collection|
        _, components = collection

        recurrable(components).each do |component|
          instances = event_instances(component.uid, components).sort_by(&:dtstart)

          count = add_occurrences(memo, component, instances, options)
          remaining = options[:count] ? options[:count] - count : nil
          add_remaining_instances(memo, instances, options, remaining)
        end
      
        memo
      end.sort{|a,b| a.dtstart <=> b.dtstart}

      options[:count] ? occs.first([options[:count],0].max) : occs
    end
    
    private

    def add_occurrences(memo, component, instances, options)
      unless component.bounded?(options)
        raise ArgumentError.new("This component is unbounded, cannot enumerate occurrences!")
      end

      yielded_occurrences = 0
      yielded_instances   = 0
      
      # enumerate occurrences of the recurring component
      component.each(options.reject{|k,_|:count == k}) do |occurrence|
        break if yielded_occurrences >= options[:count] if options[:count]
        break if yielded_instances   >= options[:count] if options[:count]

        if instance = next_instance(instances, occurrence)
          if instance.occurrences(options).first
            memo << instance
            yielded_instances += 1
          end
        else
          memo << occurrence
          yielded_occurrences += 1
        end
      end
      yielded_occurrences
    end
    
    def add_remaining_instances(memo, instances, options, count)
      yielded = 0
      instances.each do |override|
        break if yielded >= count if count
        if instance = override.occurrences(options).first
          memo << instance
          yielded += 1
        end
      end
    end      
    
    def next_instance(instances, occurrence)
      found = nil
      instances.delete_if do |i|
        if i.recurrence_id == occurrence.dtstart
          found = i
        end
      end
      found
    end

    def recurring_subcomponents
      subcomponents.select{ |k,v| %(VEVENT VTODO VJOURNAL).include?(k) } 
    end
    
    def recurrable(components)
      components.select{|c| ! c.recurrence_id}
    end

    def event_instances(uid, components)
      components.select{|c| uid == c.uid && c.recurrence_id}
    end
  end
end
