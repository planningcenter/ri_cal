require File.join(File.dirname(__FILE__), %w[.. spec_helper])

describe RiCal::Component::Calendar do

  context "google calendar" do

    subject {
      File.open(File.join(File.dirname(__FILE__), %w[.. .. sample_ical_files gcal.ics])) do |file|
        RiCal.parse(file)
      end.first
    }

    its(:events) { should have(2).items }
    its(:occurrences) { should have(8).items }

  end
end
