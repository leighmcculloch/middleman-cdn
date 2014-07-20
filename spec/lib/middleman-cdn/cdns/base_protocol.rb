shared_examples "BaseCDN" do
  describe ".key" do
    it "should have value" do
      expect(described_class.key).to be_present
    end
  end

  describe ".example_configuration_elements" do
    it "should return a Hash" do
      expect(described_class.example_configuration_elements).to be_a(Hash)
    end

    it "should return a Hash containing values that are arrays containing pairs of example values and comments" do
      described_class.example_configuration_elements.each do |key, value|
        expect(value).to be_a(Array)
        expect(value.length).to eq(2)
      end
    end
  end

  describe ".example_configuration" do
    before do
      expect(described_class).to receive(:example_configuration_elements).and_return({
        key1: ['"value"', "# comment"],
        key2: [["arr1", "arr2"], "#"]
      })
    end

    it "should output example keys containing the keys, values and comments" do
      expect(described_class.example_configuration).to eq(
      <<-TEXT
  cdn.#{described_class.key} = {
    key1: "value",             # comment
    key2: ["arr1", "arr2"],    #
  }
TEXT
      )
    end
  end

  describe "#say_status" do
    it "should use the Cli CDN class to say status" do
      expect(::Middleman::Cli::CDN).to receive(:say_status).with(described_class.key, "status text", newline: false, header: false, wait_enter: false)
      subject.say_status("status text", newline: false, header: false)
    end

    it "should use the Cli CDN class to say status with defaults" do
      expect(::Middleman::Cli::CDN).to receive(:say_status).with(described_class.key, "status text", newline: true, header: true, wait_enter: false)
      subject.say_status("status text")
    end
  end
end
