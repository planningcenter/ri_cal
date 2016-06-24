module RiCal
  module CalendarOccurrences
    # Return occurrences for all recurrable subcomponents of a calendar
    def occurrences(options={})
      occs = recurring_subcomponents.inject([]) do |memo, collection|
        _, components = collection

        # TODO: overrides contains all overrides for all UID's
        overrides = instances(components)
        
        options_without_count = options.reject{|k,_|:count == k}

        # find all occurrences excluding those that have an override (specific instance)
        recurrable(components).each do |component|
          yielded = 0
          component.each(options_without_count) do |occurrence|
            break if yielded >= options[:count] if options[:count]
            
            # TODO: scope this to the UID
            unless cancelled?(overrides, occurrence)
              memo << occurrence
              yielded += 1
            end
          end
        end
      
        # add all specific instances (within range defined by options)
        overrides.each do |override|
          if instance = override.occurrences(options).first
            memo << instance
          end
        end
      
        memo
      end.sort{|a,b| a.dtstart <=> b.dtstart}

      options[:count] ? occs.first(options[:count]) : occs
    end
    
    private
    
    def cancelled?(overrides, occurrence)
      overrides.find{ |i| i.recurrence_id == occurrence.dtstart }
    end

    def recurring_subcomponents
      subcomponents.select{ |k,v| %(VEVENT VTODO VJOURNAL).include?(k) } 
    end
    
    def recurrable(components)
      components.select{|c| !c.recurrence_id}
    end

    def instances(components)
      components.select{|c| c.recurrence_id}
    end
  end
end
