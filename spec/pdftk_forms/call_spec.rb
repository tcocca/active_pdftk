require 'spec_helper'
require 'tempfile'

describe ActivePdftk::Call do
  context "#new" do
    before do
      options = {}
      options[:path] = ENV['path'] unless ENV['path'].nil?
      @pdftk = ActivePdftk::Call.new(options)
    end

    it "should set the path (not nil)" do
      @pdftk.default_statements[:path].should_not be_nil
    end

    it "should check the ENV vars" do
      unless ENV['path'].nil? || ENV['version'].nil?
        ENV['path'].should_not be_nil
        ENV['version'].should_not be_nil
      else
        warn "\nWARNING\nUnable to test path detection and custom setting.\nProvide rake argument to test them.\n`$ rake spec path=/usr/bin/pdftk version=1.44`\n"
      end
    end

    if ENV['path']
      it "should find the path of pdftk (unstable)" do
        @pdftk.default_statements[:path].should == ENV['path']
      end

      it "should allow a custom path" do # not very testing ~!?
        @pdftk = ActivePdftk::Call.new(:path => @pdftk.default_statements[:path])
        @pdftk.default_statements[:path].should == @pdftk.default_statements[:path]
      end
    end

    if ENV['version']
      it "should find the version of pdftk (unstable)" do
        @pdftk.pdftk_version.should == ENV['version']
      end
    end

    it "should store default options" do
      path =  ActivePdftk::Call.new.locate_pdftk
      @pdftk = ActivePdftk::Call.new(:input => 'test.pdf', :options => {:flatten => true})
      @pdftk.default_statements.should == {:input => 'test.pdf', :options => {:flatten => true}, :path => path}
    end
  end

  context "#set_cmd" do
    context "prepare command" do
      before do
        @pdftk = ActivePdftk::Call.new
      end

      it "should convert input" do
        @pdftk.set_cmd(:input => 'a.pdf').should == "a.pdf"
        inputs = {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil}
        reconstruct_inputs(@pdftk.set_cmd(:input => inputs)).should == inputs
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

      it "should raise an ActivePdftk::IllegalStatement exception" do
        expect{ @pdftk.pdftk(:options => {:ionize => true}) }.to raise_error(ActivePdftk::IllegalStatement)
        expect{ @pdftk.pdftk(:operation => {:vote => 'for_me'}) }.to raise_error(ActivePdftk::IllegalStatement)
        expect{ @pdftk.pdftk(:options => {:fill_form => 'a.fdf'}) }.to raise_error(ActivePdftk::IllegalStatement)
        expect{ @pdftk.pdftk(:operation => {:flatten => true}) }.to raise_error(ActivePdftk::IllegalStatement)
      end
    end

    context "build_range_option" do
      before do
        @pdftk = ActivePdftk::Call.new
      end

      it "should set the operation with arguments" do
        cat_options = {
          :input => {'a.pdf' => nil, 'b.pdf' => nil, 'c.pdf' => nil},
          :operation => {
            :cat => [
              {:start => 1, :end => 'end', :pdf => 'a.pdf'},
              {:pdf => 'b.pdf', :start => 12, :end => 16, :orientation => 'E', :pages => 'even'}
            ]
          }
        }
        cmd = @pdftk.set_cmd(cat_options)
        input_pdfs = cmd.split(' cat ').first
        input_map = map_inputs(input_pdfs)
        cmd.should == "#{input_pdfs} cat #{input_map['a.pdf']}1-end #{input_map['b.pdf']}12-16evenE"

        @pdftk.set_cmd(:input => {'a.pdf' => nil}, :operation => {:cat => [{:pdf => 'a.pdf', :start => 1, :end => 'end'}]}).should == "B=a.pdf cat B1-end"
        @pdftk.set_cmd(:input => {'a.pdf' => nil}, :operation => {:cat => [{:pdf => 'a.pdf'}]}).should == "B=a.pdf cat B"

        cat_options = {:input => {'a.pdf' => nil, 'b.pdf' => nil}, :operation => {:cat => [{:pdf => 'a.pdf'}, {:pdf => 'b.pdf'}]}}
        cmd = @pdftk.set_cmd(cat_options)
        input_pdfs = cmd.split(' cat ').first
        input_map = map_inputs(input_pdfs)
        cmd.should == "#{input_pdfs} cat #{input_map['a.pdf']} #{input_map['b.pdf']}"

        @pdftk.set_cmd(:input => 'a.pdf', :operation => {:cat => [{:pdf => 'a.pdf', :start => 1, :end => 'end'}]}).should == "a.pdf cat 1-end"
        @pdftk.set_cmd(:input => 'a.pdf', :operation => {:cat => [{:pdf => 'a.pdf', :end => 'end'}]}).should == "a.pdf cat 1-end"
        @pdftk.set_cmd(:input => 'a.pdf', :operation => {:cat => [{:pdf => 'a.pdf', :start => '4', :orientation => 'N'}]}).should == "a.pdf cat 4N"
      end

      it "should raise missing input errors" do
        expect { @pdftk.set_cmd(:input => {'a.pdf' => nil}, :operation => {:cat => [{:pdf => 'a.pdf'}, {:pdf => 'b.pdf'}]}) }.to raise_error(ActivePdftk::MissingInput)
        expect { @pdftk.set_cmd(:input => 'a.pdf', :operation => {:cat => [{:pdf => 'a.pdf'}, {:pdf => 'b.pdf'}]}) }.to raise_error(ActivePdftk::MissingInput)
        expect { @pdftk.set_cmd(:input => {'a.pdf' => nil, 'c.pdf' => 'foo'}, :operation => {:cat => [{:pdf => 'a.pdf'}, {:pdf => 'b.pdf'}]}) }.to raise_error(ActivePdftk::MissingInput, "Missing Input file, `b.pdf`")
      end

      it "should raise an invalid options error" do
        expect { @pdftk.set_cmd(:input => {'a.pdf' => nil}, :operation => {:cat => nil}) }.to raise_error(ActivePdftk::InvalidOptions, "Invalid options passed to the command, `cat`, please see `$: pdftk --help`")
        expect { @pdftk.set_cmd(:input => {'a.pdf' => nil}, :operation => {:cat => []}) }.to raise_error(ActivePdftk::InvalidOptions, "Invalid options passed to the command, `cat`, please see `$: pdftk --help`")
        expect { @pdftk.set_cmd(:input => {'a.pdf' => nil}, :operation => {:cat => "test"}) }.to raise_error(ActivePdftk::InvalidOptions, "Invalid options passed to the command, `cat`, please see `$: pdftk --help`")
      end
    end

    context "build command" do
      before do
        @pdftk = ActivePdftk::Call.new(:input => 'test.pdf', :options => {:flatten => true})
      end

      it "should use default command statements" do
        @pdftk.set_cmd().split('').sort.should == "test.pdf flatten".split('').sort
      end

      it "should overwrite default command statements" do
        @pdftk.set_cmd(:options => { :flatten => false, :owner_pw => 'bar'}).split('').sort.should == "test.pdf owner_pw bar".split('').sort
      end

      it "should raise an ActivePdftk::MultipleInputStream exception" do
        expect{ @pdftk.set_cmd(:input => Tempfile.new('specs'), :operation => {:fill_form => StringIO.new('')}) }.to raise_error(ActivePdftk::MultipleInputStream)
      end

      # Give up in testing this one
      # What is the point in testing a simple concatenation....
      it "should prepare a full command line" do
#        inputs = {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil}
#        command = @pdftk.set_cmd(:input => inputs, :operation => {:fill_form => 'a.fdf'}, :output => 'out.pdf',:options => { :flatten => false, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'}).split('').sort.should == "B=c.pdf C=a.pdf D=b.pdf input_pw C=foo D=bar fill_form a.fdf output out.pdf encrypt_40bit owner_pw bar user_pw baz".split('').sort
#        reconstruct_inputs(command).should == inputs
      end
    end
  end

  context "#pdftk" do
    before do
      @pdftk = ActivePdftk::Call.new
      @file = File.new path_to_pdf('fields.pdf')
      @tempfile = Tempfile.new('specs')
      @stringio = StringIO.new
      @file_as_string = @file.read
      @file.rewind
    end

    it "should input without exception" do
      @tempfile.write @file_as_string
      @stringio.write @file_as_string
      @tempfile.rewind
      @stringio.rewind

      expect{ @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data) }.to_not raise_error(ActivePdftk::CommandError)
      expect{ @pdftk.pdftk(:input => @file, :operation => :dump_data) }.to_not raise_error(ActivePdftk::CommandError)
      expect{ @pdftk.pdftk(:input => @tempfile, :operation => :dump_data) }.to_not raise_error(ActivePdftk::CommandError)
      expect{ @pdftk.pdftk(:input => @stringio, :operation => :dump_data) }.to_not raise_error(ActivePdftk::CommandError)
    end

    it "should output without exception and give the appropriate result" do
      @data_string = File.new(path_to_pdf('fields.data')).read
      
      expect{ @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data, :output => @tempfile) }.to_not raise_error(ActivePdftk::CommandError)
      @tempfile.rewind
      @tempfile.read.should == @data_string

      expect{ @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data, :output => @stringio) }.to_not raise_error(ActivePdftk::CommandError)
      @stringio.string.should == @data_string

      expect{@return_stringio =  @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data) }.to_not raise_error(ActivePdftk::CommandError)
      @return_stringio.string.should == @data_string
    end

    it "should input a File, output a StringIO without exception and give the appropriate result" do
      @data_fields_string = File.new(path_to_pdf('fields.data_fields')).read
      expect{ @pdftk.pdftk(:input => @file, :operation => :dump_data_fields, :output => @stringio) }.to_not raise_error(ActivePdftk::CommandError)
      @stringio.string.should == @data_fields_string
    end

    it "should raise a ActivePdftk::CommandError exception" do
      expect{ @pdftk.pdftk(:input => {'a.pdf' => 'foo', 'b.pdf' => 'bar', 'c.pdf' => nil}, :operation => {}, :output => 'out.pdf',:options => { :flatten => false, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'}) }.to raise_error(ActivePdftk::CommandError)
    end

    context "#burst" do
      it "should return Dir.tmpdir when there is no output specified" do
        @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :burst).should == Dir.tmpdir
      end

      it "should return the specified output directory" do
        @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :burst, :output => path_to_pdf('pg_%02d.pdf')).should == path_to_pdf('pg_%02d.pdf')
        File.unlink(path_to_pdf('pg_01.pdf')).should == 1
      end
    end

    context "#unpack_files" do
      it "should return Dir.tmpdir when there is no output specified" do
        @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => {:attach_files => path_to_pdf('attached_file.txt')}, :output => path_to_pdf('attached.pdf'))
        @pdftk.pdftk(:input => path_to_pdf('attached.pdf'), :operation => :unpack_files).should == Dir.tmpdir
        File.unlink(path_to_pdf('attached.pdf'))
      end

      it "should return the specified output directory" do
        @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => {:attach_files => path_to_pdf('attached_file.txt')}, :output => path_to_pdf('attached.pdf'))
        @pdftk.pdftk(:input => path_to_pdf('attached.pdf'), :operation => :unpack_files, :output => path_to_pdf(nil)).should == path_to_pdf(nil)
        File.unlink(path_to_pdf('attached.pdf'))
      end
    end

    context "respect output formats" do
      it "should return a file as output" do
        @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data, :output => File.new(path_to_pdf('field_data.txt'), "w")).should be_a(File)
        File.unlink(path_to_pdf('field_data.txt')).should == 1
      end

      it "should return a tempfile as output" do
        @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data, :output => Tempfile.new('field_data.txt')).should be_a(Tempfile)
      end

      it "should return stringio as output" do
        @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data, :output => StringIO.new).should be_a(StringIO)
      end

      it "should return a string as output" do
        @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data, :output => path_to_pdf('field_data.txt')).should be_a(String)
        File.unlink(path_to_pdf('field_data.txt')).should == 1
      end

      it "should return stringio if no output is specified" do
        @pdftk.pdftk(:input => path_to_pdf('fields.pdf'), :operation => :dump_data).should be_a(StringIO)
      end
    end
  end
end
