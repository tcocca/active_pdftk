require 'spec_helper'
require 'tempfile'

describe PdftkForms::Call do
  context "#new" do
    before do
      @pdftk = PdftkForms::Call.new
    end
    it "should set the path (not nil)" do
      @pdftk.default_statements[:path].should_not be_nil
    end

    if ENV['path']
      it "should find the path of pdftk (unstable)" do
        @pdftk.default_statements[:path].should == ENV['path']
      end

      it "should allow a custom path" do # not very testing ~!?
        @pdftk = PdftkForms::Call.new(:path => @pdftk.default_statements[:path])
        @pdftk.default_statements[:path].should == @pdftk.default_statements[:path]
      end
    end

    if ENV['version']
      it "should find the version of pdftk (unstable)" do
        @pdftk.pdftk_version.should == ENV['version']
      end
    end

    it "WARNING\nUnable to test path detection and custom setting.\nProvide rake argument to test them.\n`$ rake spec path=/usr/bin/pdftk version=1.44`" do
      ENV['path'].should_not be_nil
      ENV['version'].should_not be_nil
    end

    it "should store default options" do
      @pdftk = PdftkForms::Call.new(:input => 'test.pdf', :options => {:flatten => true})
      @pdftk.default_statements.should == {:input => 'test.pdf', :options => {:flatten => true}, :path => PdftkForms::Call.new.locate_pdftk}
    end
  end

  context "#set_cmd" do
      # Because with Ruby 1.8 Hashes are unordered, and options in cli are unordered too,
      # two command lines could seems different but have the same behaviour.
      # With Ruby 1.9 command line should always be identical.
      # In order to specs this we compare a sorted array of characters composing the command line
      # it is not bulletproof but command line anagrams are very unlikely.
      # Anybody with a better solution should make a proposal.

    context "prepare command" do
      before do
        @pdftk = PdftkForms::Call.new
      end
      it "should convert input" do
        @pdftk.set_cmd(:input => 'a.pdf').should == "a.pdf"
        @pdftk.set_cmd(:input => {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil}).split('').sort.should == "B=c.pdf C=a.pdf D=b.pdf input_pw C=foo D=bar".split('').sort
        @pdftk.set_cmd(:input => File.new(path_to_pdf('fields.pdf'))).should == "-"
        @pdftk.set_cmd(:input => Tempfile.new('specs')).should == "-"
        @pdftk.set_cmd(:input => StringIO.new('specs')).should == "-"
      end

      it "should convert operation" do
        @pdftk.set_cmd(:operation => {:fill_form => 'a.fdf'}).should == "fill_form a.fdf"
        @pdftk.set_cmd(:operation => {:fill_form => Tempfile.new('specs')}).should == "fill_form -"
        @pdftk.set_cmd(:operation => {}).should == ""
        @pdftk.set_cmd(:operation => 'dump_data_fields').should == "dump_data_fields"
        @pdftk.set_cmd(:operation => :dump_data_fields).should == "dump_data_fields"
        @pdftk.set_cmd(:operation => {:dump_data => nil}).should == "dump_data"
        @pdftk.set_cmd(:operation => {:update_info => 'a.info'}).should == "update_info a.info"
      end

      it "should convert options" do
        @pdftk.set_cmd(:options => {:owner_pw => 'bar'}).split('').sort.should == "owner_pw bar".split('').sort
        @pdftk.set_cmd(:options => {:encrypt  => :'40bit'}).split('').sort.should == "encrypt_40bit".split('').sort
        @pdftk.set_cmd(:options => {:allow  => ['DegradedPrinting', :assembly]}).split('').sort.should == "allow degradedprinting assembly".split('').sort
      end

      it "should convert output" do
        @pdftk.set_cmd(:output => 'a.pdf').should == "output a.pdf"
        @pdftk.set_cmd(:output => File.new(path_to_pdf('fields.pdf'))).should == "output -"
        @pdftk.set_cmd(:output => Tempfile.new('specs')).should == "output -"
        @pdftk.set_cmd(:output => StringIO.new('specs')).should == "output -"
      end

      it "should raise an PdftkForms::IllegalStatement exception" do
        expect{ @pdftk.pdftk(:options => {:ionize => true}) }.to raise_error(PdftkForms::IllegalStatement)
        expect{ @pdftk.pdftk(:operation => {:vote => 'for_me'}) }.to raise_error(PdftkForms::IllegalStatement)
        expect{ @pdftk.pdftk(:options => {:fill_form => 'a.fdf'}) }.to raise_error(PdftkForms::IllegalStatement)
        expect{ @pdftk.pdftk(:operation => {:flatten => true}) }.to raise_error(PdftkForms::IllegalStatement)
      end
    end

    context "build command" do
      before do
        @pdftk = PdftkForms::Call.new(:input => 'test.pdf', :options => {:flatten => true})
      end

      it "should use default command statements" do
        @pdftk.set_cmd().split('').sort.should == "test.pdf flatten".split('').sort
      end

      it "should overwrite default command statements" do
        @pdftk.set_cmd(:options => { :flatten => false, :owner_pw => 'bar'}).split('').sort.should == "test.pdf owner_pw bar".split('').sort
      end

      it "should raise an PdftkForms::MultipleInputStream exception" do
        expect{ @pdftk.set_cmd(:input => Tempfile.new('specs'), :operation => {:fill_form => StringIO.new('')}) }.to raise_error(PdftkForms::MultipleInputStream)
      end

      it "should prepare a full command line" do
        @pdftk.set_cmd(:input => {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil}, :operation => {:fill_form => 'a.fdf'}, :output => 'out.pdf',:options => { :flatten => false, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'}).split('').sort.should == "B=c.pdf C=a.pdf D=b.pdf input_pw C=foo D=bar fill_form a.fdf output out.pdf encrypt_40bit owner_pw bar user_pw baz".split('').sort
      end
    end
  end

  context "#pdftk" do
    before do
      @pdftk = PdftkForms::Call.new
      @file = File.new path_to_pdf('fields.pdf')
      @tempfile = Tempfile.new 'specs'
      @stringio = StringIO.new

      @file_as_string = @file.read
      @file.rewind
    end

    it "should input without exception" do
      @tempfile.write @file_as_string
      @stringio.write @file_as_string
      @tempfile.rewind
      @stringio.rewind

      expect{ @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data) }.to_not raise_error(PdftkForms::CommandError)
      expect{ @pdftk.pdftk(:input => @file, :operation => :dump_data) }.to_not raise_error(PdftkForms::CommandError)
      expect{ @pdftk.pdftk(:input => @tempfile, :operation => :dump_data) }.to_not raise_error(PdftkForms::CommandError)
      expect{ @pdftk.pdftk(:input => @stringio, :operation => :dump_data) }.to_not raise_error(PdftkForms::CommandError)
    end

    it "should output without exception and give the appropriate result" do
      @data_string = File.new(path_to_pdf('fields.data')).read
      
      expect{ @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data, :output => @tempfile) }.to_not raise_error(PdftkForms::CommandError)
      @tempfile.rewind
      @tempfile.read.should == @data_string

      expect{ @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data, :output => @stringio) }.to_not raise_error(PdftkForms::CommandError)
      @stringio.string.should == @data_string

      expect{@return_stringio =  @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data) }.to_not raise_error(PdftkForms::CommandError)
      @return_stringio.string.should == @data_string
    end

    it "should input a File, output a StrinIO without exception and give the appropriate result" do
      @data_fields_string = File.new(path_to_pdf('fields.data_fields')).read
      expect{ @pdftk.pdftk(:input => @file, :operation => :dump_data_fields, :output => @stringio) }.to_not raise_error(PdftkForms::CommandError)
      @stringio.string.should == @data_fields_string
    end

    it "should raise a PdftkForms::CommandError exception" do
      expect{ @pdftk.pdftk(:input => {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil}, :operation => {}, :output => 'out.pdf',:options => { :flatten => false, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'}) }.to raise_error(PdftkForms::CommandError)
    end
  end
end
